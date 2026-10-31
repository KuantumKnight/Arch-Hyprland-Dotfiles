#!/usr/bin/env bash
set -euo pipefail
exec "$HOME/.config/viegphunt/set-wallpaper.sh" "${1:?Wallpaper path}"
