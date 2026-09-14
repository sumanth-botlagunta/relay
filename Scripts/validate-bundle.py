#!/usr/bin/env python3
"""Check release metadata and binary compatibility before packaging."""
from pathlib import Path
import plistlib
import re
import subprocess

root = Path(__file__).resolve().parent.parent
bundle = root / 'dist/Relay.app'
info = plistlib.loads((bundle / 'Contents/Info.plist').read_bytes())
version = re.search(r'current = "([^"]+)"', (root / 'Sources/RelayCore/Version.swift').read_text()).group(1)
assert info['CFBundleShortVersionString'] == version, 'App and source versions differ'
assert info['CFBundleIdentifier'] == 'org.relaybrowser.Relay', 'Unexpected bundle identifier'
assert info['LSMinimumSystemVersion'] == '15.0', 'Unexpected minimum macOS version'
assert info['CFBundleExecutable'] == 'Relay' and info['CFBundlePackageType'] == 'APPL'
assert info['LSUIElement'] is True
assert info['NSAppleEventsUsageDescription'], 'Missing Automation permission description'
assert (bundle / 'Contents/Resources/LICENSE').read_bytes() == (root / 'LICENSE').read_bytes()
binary = bundle / 'Contents/MacOS/Relay'
architectures = subprocess.check_output(['lipo', str(binary), '-archs'], text=True).strip()
assert architectures == 'arm64', f'Expected only Apple Silicon, got {architectures}'
load_commands = subprocess.check_output(['otool', '-l', str(binary)], text=True)
assert re.search(r'\bminos 15\.0\b', load_commands), 'Binary deployment target differs from Info.plist'
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(bundle)], check=True)
print(f'Relay {version}: metadata, arm64, macOS 15 deployment target, license, and signature verified.')
