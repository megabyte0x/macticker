#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:-run}"
work="$(mktemp -d "${TMPDIR:-/tmp}/ticker.XXXXXX")"
trap 'if [[ -n "${mounted:-}" ]]; then hdiutil detach -quiet "$mounted"; fi; rm -rf "$work"' EXIT
SIGN_IDENTITY=-
if [[ "$MODE" == --dmg ]]; then
  CONFIG=release
  APP="$work/stage/Ticker.app"
  SIGN_IDENTITY="${TICKER_SIGN_IDENTITY:--}"
else
  pkill -x Ticker 2>/dev/null || true
  CONFIG=debug
  APP="$PWD/dist/Ticker.app"
fi
swift build -c "$CONFIG"

iconset="$work/Ticker.iconset"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$iconset"
cp "$(swift build -c "$CONFIG" --show-bin-path)/Ticker" "$APP/Contents/MacOS/Ticker"
for size in 16 32 128 256 512; do
  for scale in 1 2; do
    name="icon_${size}x${size}"
    if [[ "$scale" == 2 ]]; then name+="@2x"; fi
    pixels=$((size * scale))
    sips -s format png -z "$pixels" "$pixels" website/public/favicon.svg \
      --out "$iconset/$name.png" >/dev/null
  done
done
iconutil -c icns -o "$APP/Contents/Resources/Ticker.icns" "$iconset"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Ticker</string>
<key>CFBundleIdentifier</key><string>com.megabyte.ticker</string>
<key>CFBundleName</key><string>Ticker</string>
<key>CFBundleDisplayName</key><string>Ticker</string>
<key>CFBundleIconFile</key><string>Ticker.icns</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST
VERSION="${TICKER_VERSION:-1.1.0}"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$VERSION" "$APP/Contents/Info.plist"
if [[ "$SIGN_IDENTITY" == - ]]; then
  codesign --force --sign - "$APP"
else
  codesign --force --sign "$SIGN_IDENTITY" --options runtime --timestamp "$APP"
fi
case "$MODE" in
  --dmg)
    mkdir -p dist "$work/mount"
    ln -s /Applications "$work/stage/Applications"
    cp "$APP/Contents/Resources/Ticker.icns" "$work/stage/.VolumeIcon.icns"
    hdiutil create -quiet -srcfolder "$work/stage" -volname Ticker -fs APFS -format UDRW "$work/Ticker.dmg"
    hdiutil attach -quiet -nobrowse -mountpoint "$work/mount" "$work/Ticker.dmg"
    mounted="$work/mount"
    # Finder reads the volume's custom-icon flag, not the staging folder's.
    xcrun SetFile -a C "$mounted"
    hdiutil detach -quiet "$mounted"
    unset mounted
    hdiutil convert -quiet "$work/Ticker.dmg" -format UDZO -o "$work/Ticker-final.dmg"
    if [[ "$SIGN_IDENTITY" != - ]]; then
      codesign --sign "$SIGN_IDENTITY" --timestamp "$work/Ticker-final.dmg"
    fi
    mv -f "$work/Ticker-final.dmg" dist/Ticker.dmg
    echo "Built dist/Ticker.dmg (not notarized)"
    ;;
  --debug) lldb -- "$APP/Contents/MacOS/Ticker" ;;
  --logs|--telemetry)
    open -n "$APP"
    /usr/bin/log stream --info --style compact --predicate 'process == "Ticker"'
    ;;
  --verify)
    open -n "$APP"
    sleep 2
    pgrep -x Ticker
    ;;
  run) open -n "$APP" ;;
  *) echo "usage: $0 [--debug|--dmg|--logs|--telemetry|--verify]" >&2; exit 2 ;;
esac
