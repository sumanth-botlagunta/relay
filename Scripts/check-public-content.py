#!/usr/bin/env python3
"""Conservative checks on the staged/tracked public tree; never print secret values."""
from pathlib import Path
import re
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
PATTERNS = {
    "private key": re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"),
    "GitHub token": re.compile(rb"(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,})"),
    "AWS access key": re.compile(rb"(?:AKIA|ASIA)[A-Z0-9]{16}"),
    "Slack token": re.compile(rb"xox[baprs]-[A-Za-z0-9-]{20,}"),
    "personal email": re.compile(rb"[A-Za-z0-9._%+-]+@(?:gmail|yahoo|hotmail|outlook|icloud|protonmail)\.[A-Za-z]{2,}", re.I),
    "local home path": re.compile(rb"/(?:Users|home)/[A-Za-z0-9._-]+/"),
}
FORBIDDEN_PARTS = {".build", "dist", ".codex", ".agents", "xcuserdata", "private-pre-open-source"}
FORBIDDEN_SUFFIXES = {".pem", ".key", ".p12", ".p8", ".mobileprovision", ".bundle", ".dmg", ".zip"}


def check() -> int:
    names = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
    failures = []
    checked = 0
    for name in filter(None, names):
        path = ROOT / name
        # Removed files may still appear in the index during a local pre-stage check.
        if not path.exists():
            continue
        if path.is_symlink():
            failures.append((name, "unexpected symlink"))
            continue
        checked += 1
        if (set(Path(name).parts) & FORBIDDEN_PARTS or path.suffix in FORBIDDEN_SUFFIXES
                or path.name.startswith(".env") or path.name.startswith("settings.json")
                or path.name == "AGENT-PROMPT.md"):
            failures.append((name, "private/generated artifact"))
        data = path.read_bytes()
        for label, pattern in PATTERNS.items():
            if pattern.search(data):
                failures.append((name, label))
        if path.suffix in {".jpg", ".jpeg"}:
            if not data.startswith(b"\xff\xd8"):
                failures.append((name, "invalid JPEG"))
                continue
            offset = 2
            while offset + 4 <= len(data):
                if data[offset] != 255:
                    failures.append((name, "invalid JPEG marker"))
                    break
                marker = data[offset + 1]
                if marker in {0xDA, 0xD9}:
                    break
                if marker in {0xE1, 0xED, 0xFE}:
                    failures.append((name, "image metadata requires review/removal"))
                size = int.from_bytes(data[offset + 2:offset + 4], "big")
                if size < 2:
                    failures.append((name, "invalid JPEG segment"))
                    break
                offset += 2 + size
        if path.suffix == ".png":
            if not data.startswith(b"\x89PNG\r\n\x1a\n"):
                failures.append((name, "invalid PNG"))
                continue
            offset = 8
            while offset + 12 <= len(data):
                size = struct.unpack(">I", data[offset:offset + 4])[0]
                kind = data[offset + 4:offset + 8]
                if kind in {b"tEXt", b"zTXt", b"iTXt", b"eXIf"}:
                    failures.append((name, "image metadata requires review/removal"))
                offset += 12 + size
    if failures:
        for name, label in failures:
            print(f"FAIL {name}: {label}")
        return 1
    print(f"Public-content checks passed for {checked} tracked files. Manual review is still required.")
    return 0


if __name__ == "__main__":
    sys.exit(check())
