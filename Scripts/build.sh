#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP=Relay
BUNDLE="dist/$APP.app"
BUILD_PATH="${RELAY_BUILD_PATH:-.build}"

if [ ! -f Resources/AppIcon.icns ]; then
  swift Scripts/makeicon.swift
  mkdir -p Resources/AppIcon.iconset
  for s in 16 32 128 256 512; do
    sips -z "$s" "$s" Resources/icon-1024.png --out "Resources/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
    d=$((s * 2))
    sips -z "$d" "$d" Resources/icon-1024.png --out "Resources/AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
fi

if [ "${1:-}" != "install-built" ]; then
  build_args=(--disable-sandbox -c release --scratch-path "$BUILD_PATH" --product Relay
    -Xswiftc -file-prefix-map -Xswiftc "$PWD=."
    -Xswiftc -debug-prefix-map -Xswiftc "$PWD=.")
  build_args+=(--arch "${RELAY_ARCH:-arm64}")
  swift build "${build_args[@]}"
  bin_path=$(swift build "${build_args[@]}" --show-bin-path)
  mkdir -p dist
  stage=$(mktemp -d "$PWD/dist/.relay-build.XXXXXX")
  trap 'rm -rf "$stage"' EXIT
  mkdir -p "$stage/$APP.app/Contents/MacOS" "$stage/$APP.app/Contents/Resources"
  cp "$bin_path/$APP" "$stage/$APP.app/Contents/MacOS/$APP"
  strip -S "$stage/$APP.app/Contents/MacOS/$APP"
  cp Resources/Info.plist "$stage/$APP.app/Contents/Info.plist"
  cp Resources/AppIcon.icns "$stage/$APP.app/Contents/Resources/AppIcon.icns"
  cp LICENSE "$stage/$APP.app/Contents/Resources/LICENSE"
  codesign --force --sign - "$stage/$APP.app"
  codesign --verify --deep --strict "$stage/$APP.app"
  # Only replace this generated bundle, never other files in dist (e.g. backups).
  rm -rf "$BUNDLE"
  mv "$stage/$APP.app" "$BUNDLE"
  rm -rf "$stage"
  trap - EXIT
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$PWD/$BUNDLE" >/dev/null 2>&1 || true
  echo "Built $BUNDLE"
fi

if [ "${1:-}" = "install" ] || [ "${1:-}" = "install-built" ]; then
  codesign --verify --deep --strict "$BUNDLE"
  if pgrep -f '^/Applications/Relay.app/Contents/MacOS/Relay$' >/dev/null; then
    echo "Quit Relay from its menu, then run ./Scripts/build.sh install-built."
    exit 1
  fi
  stamp=$(date +%Y%m%d-%H%M%S)
  stage=$(mktemp -d /Applications/.relay-install.XXXXXX)
  rollback() {
    if [ -d "$stage/previous" ] && [ ! -e "/Applications/$APP.app" ]; then
      mv "$stage/previous" "/Applications/$APP.app"
    fi
    rm -rf "$stage"
  }
  trap rollback EXIT
  ditto "$BUNDLE" "$stage/$APP.app"
  codesign --verify --deep --strict "$stage/$APP.app"
  if [ -d "/Applications/$APP.app" ]; then
    ditto -c -k --sequesterRsrc --keepParent "/Applications/$APP.app" "dist/Relay-backup-$stamp.zip"
    mv "/Applications/$APP.app" "$stage/previous"
  fi
  mv "$stage/$APP.app" "/Applications/$APP.app"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/$APP.app"
  # Keep a recoverable archive, not a second discoverable app bundle.
  rm -rf "$BUNDLE"
  echo "Installed /Applications/$APP.app. Open it to continue. Previous version archived in dist."
fi
