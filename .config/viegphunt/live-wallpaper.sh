#!/usr/bin/env bash
set -euo pipefail
IFS= read -r wallpaper < "$HOME/.config/hypr/wallpaper"
[[ -f "$wallpaper" ]] || exit 1
case "${wallpaper,,}" in
    *.mp4|*.mkv|*.webm|*.mov|*.gif) ;;
    *) exit 0 ;;
esac
exec mpvpaper -p -o "no-audio loop-file=inf hwdec=auto-safe panscan=1" ALL "$wallpaper"
