#!/usr/bin/env bash
set -euo pipefail
pkill -u "$UID" -x rofi || true
if ! selection=$(cliphist list | rofi -no-config -theme "$HOME/.config/rofi/adi-menus/clipboard.rasi" \
    -dmenu -i -no-custom -p 'Clipboard' -display-columns 2); then
    exit 0
fi
[[ -n "$selection" ]] || exit 0
printf '%s\n' "$selection" | cliphist decode | wl-copy
