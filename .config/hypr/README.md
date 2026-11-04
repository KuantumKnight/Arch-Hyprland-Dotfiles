# Hyprland configuration

The active setup uses the Lua entry point and the modules in `conf/`. The
legacy `.conf` snippets are retained as reference material from the earlier
configuration. Edit `conf/settings.lua` for monitor, scaling, input, and visual
preferences. `conf/bindings.lua` contains the keybindings.

The wallpaper path file is local state and is created by `install.sh`. Put
images or videos in `~/Pictures/Wallpapers`; Super+W opens the picker and
Super+Shift+W selects another image.

## Desktop menus and live wallpapers

Super+A is the app launcher. Alt+Space and Super+R are unassigned. Super+. opens
the adi1090x-style emoji grid, Super+V clipboard history, and Super+H shortcut hints.
The menu themes live in `~/.config/rofi/adi-menus/`.
Images and videos belong in `~/Pictures/Wallpapers`. Live files use mpvpaper via
`hypr-live-wallpaper.service`; selecting a still stops playback.
