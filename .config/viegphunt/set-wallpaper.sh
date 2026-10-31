#!/usr/bin/env bash
set -euo pipefail
wallpaper=${1:?Supply an image path}
[[ -f "$wallpaper" ]] || exit 1
case "${wallpaper,,}" in
    *.png|*.jpg|*.jpeg|*.webp|*.bmp) ;;
    *) printf 'Only still images are enabled.\n' >&2; exit 1 ;;
esac
restore=${2:-}
if [[ "$restore" == --restore ]]; then
    for ((attempt=0; attempt<40; attempt++)); do
        awww query >/dev/null 2>&1 && break
        sleep 0.05
    done
elif ! awww query >/dev/null 2>&1; then
    systemctl --user start hypr-wallpaper.service
fi
exec 9>"$XDG_RUNTIME_DIR/viegphunt-wallpaper.lock"
flock -n 9 || exit 0
transition=outer
[[ "$restore" == --restore ]] && transition=none
awww img "$wallpaper" --resize crop --transition-type "$transition" --transition-pos center \
    --transition-duration 0.4 --transition-fps 60
printf '%s\n' "$wallpaper" > "$HOME/.config/hypr/wallpaper.next"
mv "$HOME/.config/hypr/wallpaper.next" "$HOME/.config/hypr/wallpaper"
state="$HOME/.local/state/caelestia/wallpaper"
if [[ -d "$state" ]]; then
    printf '%s\n' "$wallpaper" > "$state/path.next"
    mv "$state/path.next" "$state/path.txt"
    ln -sfn "$wallpaper" "$state/current"
fi
systemctl --user --no-block restart hypr-wallpaper-poster.service
