#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:-run}"
pkill -x Ticker 2>/dev/null || true
swift build
APP="$PWD/dist/Ticker.app"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build --show-bin-path)/Ticker" "$APP/Contents/MacOS/Ticker"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Ticker</string>
<key>CFBundleIdentifier</key><string>com.megabyte.ticker</string>
<key>CFBundleName</key><string>Ticker</string>
<key>CFBundleDisplayName</key><string>Ticker</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
case "$MODE" in
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
  *) echo "usage: $0 [--debug|--logs|--telemetry|--verify]" >&2; exit 2 ;;
esac
