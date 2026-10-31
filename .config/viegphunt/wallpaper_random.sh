#!/usr/bin/env bash
set -euo pipefail
current=$(cat "$HOME/.config/hypr/wallpaper" 2>/dev/null || true)
wallpaper=$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.bmp' \) | { grep -Fvx -- "$current" || true; } | shuf -n 1)
[[ -n "$wallpaper" ]] || exit 0
exec "$HOME/.config/viegphunt/set-wallpaper.sh" "$wallpaper"
