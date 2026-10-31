#!/usr/bin/env bash
set -u
export PATH="$HOME/.local/bin:$PATH"
log_dir="$HOME/.local/state/viegphunt"
mkdir -p "$log_dir" "$HOME/Pictures/Screenshots"
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/viegphunt-desktop-$UID.lock"
flock -n 9 || exit 0
start() {
    local program=$1
    shift
    if ! pgrep -xu "$UID" "$program" >/dev/null; then
        nohup "$program" "$@" >"$log_dir/$program.log" 2>&1 9>&- &
    fi
}
start nm-applet --indicator
if ! pgrep -fu "$UID" '^/usr/lib/polkit-kde-authentication-agent-1' >/dev/null; then
    nohup /usr/lib/polkit-kde-authentication-agent-1 >"$log_dir/polkit.log" 2>&1 9>&- &
fi
for type in text image; do
    if ! pgrep -fu "$UID" "^wl-paste --type $type --watch cliphist store$" >/dev/null; then
        nohup wl-paste --type "$type" --watch cliphist store >"$log_dir/clipboard-$type.log" 2>&1 9>&- &
    fi
done
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
systemctl --user start caelestia-shell.service
"$HOME/.config/viegphunt/gtkthemes.sh"
hyprctl setcursor macOS 24 >"$log_dir/cursor.log" 2>&1 || true
if [[ -s "$HOME/.config/hypr/wallpaper" ]]; then
    IFS= read -r wallpaper < "$HOME/.config/hypr/wallpaper"
    [[ -f "$wallpaper" ]] && "$HOME/.config/viegphunt/set-wallpaper.sh" "$wallpaper"
fi
