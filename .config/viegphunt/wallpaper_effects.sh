#!/usr/bin/env bash
set -euo pipefail
wallpaper=${1:-}
if [[ -z "$wallpaper" ]]; then
    IFS= read -r wallpaper < "$HOME/.config/hypr/wallpaper"
fi
[[ -f "$wallpaper" ]] || exit 0
cache="$HOME/.cache/viegphunt/wallpaper-thumbnails"
mkdir -p "$HOME/.cache/awww" "$cache"
key=$(printf '%s' "$wallpaper" | sha256sum | cut -d ' ' -f 1)
poster="$cache/$key.png"
if [[ ! -f "$poster" || "$wallpaper" -nt "$poster" ]]; then
    magick -limit thread 2 "${wallpaper}[0]" -thumbnail '1920x1920>' "$cache/$key.next.png"
    mv "$cache/$key.next.png" "$poster"
fi
cp "$poster" "$HOME/.cache/awww/normal.next.png"
mv "$HOME/.cache/awww/normal.next.png" "$HOME/.cache/awww/normal.png"
