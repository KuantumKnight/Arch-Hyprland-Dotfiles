#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.icons/default"
printf '[Icon Theme]\nInherits=macOS\n' > "$HOME/.icons/default/index.theme"
gsettings set org.gnome.desktop.interface cursor-theme macOS
hyprctl setcursor macOS 24
