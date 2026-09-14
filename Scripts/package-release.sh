#!/bin/bash
# Produce an Apple Silicon, ad-hoc signed testing release without changing the installed app.
set -euo pipefail
cd "$(dirname "$0")/.."
export COPYFILE_DISABLE=1
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)
RELAY_ARCH=arm64 ./Scripts/build.sh
python3 Scripts/validate-bundle.py
binary=dist/Relay.app/Contents/MacOS/Relay
lipo "$binary" -verify_arch arm64
codesign --verify --deep --strict dist/Relay.app
# Debug paths and local home directories must never enter distributed binaries.
if strings "$binary" | LC_ALL=C grep -E '/(Users|home)/[[:alnum:]_.-]+/' >/dev/null; then
  echo 'Release contains a local build path. Refusing to package.' >&2
  exit 1
fi
mkdir -p dist/release
stage=$(mktemp -d "$PWD/dist/.relay-package.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto --norsrc --noextattr --noqtn dist/Relay.app "$stage/Relay.app"
ln -s /Applications "$stage/Applications"
cat > "$stage/Read Me.txt" <<'TEXT'
Relay — browser picker for macOS 15 or later

Drag Relay into Applications, then open it and choose Make Default.
This testing build is ad-hoc signed and is not notarized by Apple.
If macOS blocks it, follow Apple's instructions for apps from unknown developers:
https://support.apple.com/guide/mac-help/mh40616/mac
Only approve a download whose source you trust. Do not disable Gatekeeper.

Upgrading from a private build? Quit Relay before replacing it, then make it
the default again. Check Launch at login and Automation permission if used.
Your preferences remain in ~/Library/Application Support/Relay/.
TEXT
hdiutil create -volname "Relay $version" -srcfolder "$stage" -ov -format UDZO "dist/release/Relay-$version-apple-silicon.dmg"
ditto -c -k --norsrc --noextattr --noqtn --keepParent "$stage/Relay.app" "dist/release/Relay-$version-apple-silicon.zip"
(cd dist/release && shasum -a 256 "Relay-$version-apple-silicon.dmg" "Relay-$version-apple-silicon.zip" > SHA256SUMS.txt)
# Keep distributable archives, not a second discoverable app bundle.
rm -rf dist/Relay.app
echo "Release files: dist/release/ (version $version)"
