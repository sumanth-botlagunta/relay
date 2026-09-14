# Security policy

Security fixes target the latest release. Older builds may not receive patches; there is no automatic updater yet.

## Report privately

Use [GitHub private vulnerability reporting](https://github.com/sumanth-botlagunta/relay/security/advisories/new). Include the affected version, a minimal synthetic reproduction, expected behavior, and potential impact. Do not include passwords, real browsing history, or unrelated personal data. Do not publish an exploit or sensitive report in a public issue.

If private reporting is unavailable, open an issue asking the maintainer to enable it without disclosing vulnerability details. This is a community project; no response-time or security-support SLA is promised.

## Security boundaries

Relay validates web URLs and routes them to installed apps. It does not sandbox browsers, inspect downloaded content, or provide a website reputation service. Heuristic warnings can miss dangerous links and can flag legitimate links.

Settings and saved rules live locally. Tab transfer uses macOS Automation permissions. Release downloads currently use ad-hoc signatures and checksums, and are not Apple-notarized. A checksum detects file corruption or a mismatch with the published release; it is not independent proof of publisher identity.
