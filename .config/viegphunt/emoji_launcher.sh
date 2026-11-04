#!/usr/bin/env bash
set -euo pipefail
pkill -u "$UID" -x rofi || true
exec rofi -no-config -theme "$HOME/.config/rofi/adi-menus/emoji.rasi" \
    -modi emoji -show emoji -display-emoji 'Emoji' -emoji-format '{emoji}' -emoji-mode copy
