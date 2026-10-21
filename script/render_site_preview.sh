#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
PREVIEW_TMP="$(mktemp -d /private/tmp/ticker-preview.XXXXXX)"
trap 'rm -rf "$PREVIEW_TMP"' EXIT
python3 - "$PREVIEW_TMP/TickerView.swift" <<'PY'
from pathlib import Path
import sys
source = Path('Sources/Ticker/TickerApp.swift').read_text()
Path(sys.argv[1]).write_text('import SwiftUI\n' + source[source.index('struct TickerView:'):])
PY
swiftc -parse-as-library -o "$PREVIEW_TMP/render" Sources/Ticker/TokenStore.swift "$PREVIEW_TMP/TickerView.swift" script/render_site_preview.swift
"$PREVIEW_TMP/render" "$PWD/website/public/ticker-native.png"
