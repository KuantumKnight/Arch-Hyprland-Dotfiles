#!/usr/bin/env bash
set -euo pipefail
selector="$HOME/.config/quickshell/personal-wallpaper-picker"
if quickshell list --json --path "$selector" 2>/dev/null | python -c '
import json,sys
try:
    sys.exit(0 if json.load(sys.stdin) else 1)
except ValueError:
    sys.exit(1)
'; then
    exec quickshell kill --path "$selector"
fi
exec env -u GDK_DPI_SCALE quickshell --no-duplicate --path "$selector"
