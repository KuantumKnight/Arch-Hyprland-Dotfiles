#!/usr/bin/env bash
set -euo pipefail
pkill -u "$UID" -x rofi || true
cat <<'HINTS' | rofi -dmenu -i -p 'Keybindings' -mesg 'Super = Windows key · Escape to close' >/dev/null || true
Super + K         Terminal (Kitty)
Super + E         File manager (Nemo)
Super + M         Firefox
Ctrl + Shift + Esc System monitor (btop)
Alt + Space       App launcher
Super + R         App launcher (Rofi)
Super + A         Caelestia launcher
Super + D         Caelestia dashboard
Super + N         Caelestia sidebar
Super + X         Session menu
Super + Q         Close window
Super + Shift + Q Force close window
Super + F         Toggle floating
Super + J         Toggle split
Super + P         Toggle pseudotiling
Super + L         Caelestia lock screen
Super + V         Clipboard history
Super + .         Emoji picker
Super + W         Choose wallpaper
Super + Shift + W Random wallpaper
Super + Shift + S Screenshot (save + copy)
Print Screen      Screenshot (save + copy)
Super + 1–0       Switch workspace
Super + Shift + 1–0 Move window to workspace
Super + arrows    Focus window
Super + left drag Move window
Super + right drag Resize window
Super + Shift + Ctrl + Escape Log out
HINTS
