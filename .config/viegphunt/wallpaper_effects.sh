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
    case "${wallpaper,,}" in
        *.mp4|*.mkv|*.webm|*.mov)
            ffmpeg -nostdin -hide_banner -loglevel error -y -i "$wallpaper" \
                -frames:v 1 -vf 'scale=1920:1080:force_original_aspect_ratio=decrease' \
                -threads 2 -update 1 "$cache/$key.next.png" ;;
        *) magick -limit thread 2 "${wallpaper}[0]" -thumbnail '1920x1920>' "$cache/$key.next.png" ;;
    esac
    mv "$cache/$key.next.png" "$poster"
fi
cp "$poster" "$HOME/.cache/awww/normal.next.png"
mv "$HOME/.cache/awww/normal.next.png" "$HOME/.cache/awww/normal.png"
