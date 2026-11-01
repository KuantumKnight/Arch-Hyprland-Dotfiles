# Arch Hyprland Dotfiles

My Arch Linux Hyprland rice: a Lua-based Hyprland setup, a customized
Caelestia shell, and a still-image wallpaper picker with transition effects.
It grew out of a mix of other rices and my own changes. The configs are tuned
for my setup, so review the keybindings and settings before applying them.

## Video showcase

<https://github.com/user-attachments/assets/8731de09-182c-4056-8dc9-42b70bbf54e1>

[Download the full 34-second screen recording (MP4)](media/showcase.mp4).

## What’s included

- Hyprland Lua settings, bindings, window rules, and startup hooks
- Customized Caelestia shell and settings
- Kitty, Rofi, GTK, and CAVA configuration
- Wallpaper carousel, picker, thumbnail cache, and user services
- Small launcher and desktop helper scripts

The wallpaper collection itself is not bundled. Place your own images in
`~/Pictures/Wallpapers`. The AWCC integration is optional and disabled by
default; it requires a separate Alienware GUI installation.

## Install

Designed for Arch Linux with Hyprland 0.57+ already installed (the active
config uses Hyprland’s Lua entry point). The installer installs the rice
packages from the official repositories and AUR, saves any managed
configs it replaces, then applies this tree and reloads the user systemd
daemon. It does not install Arch or replace your display manager.

```bash
git clone https://github.com/KuantumKnight/Arch-Hyprland-Dotfiles.git
cd Arch-Hyprland-Dotfiles
./install.sh
```

The installer uses `pacman` for official packages and `yay` for AUR packages.
If `yay` is missing, it builds it from the AUR after installing `base-devel`.
Review AUR build prompts before accepting them. Existing managed files are
moved under `~/.local/state/arch-hyprland-dotfiles/backups/` first.

After installation, log out and start Hyprland again. Add wallpaper images to
`~/Pictures/Wallpapers`; choose one with **Super+W**.

## Keybindings

| Shortcut | Action |
| --- | --- |
| Super+H | Show key hints |
| Super+K / Super+E | Kitty / Nemo |
| Super+M | Firefox |
| Super+A / D / N / X | Caelestia launcher / dashboard / sidebar / session menu |
| Alt+Space or Super+R | Rofi launcher |
| Super+W / Super+Shift+W | Choose / randomize wallpaper |
| Super+Q / Super+Shift+Q | Close / force close window |
| Super+L | Lock screen |
| Super+V / Super+. | Clipboard history / emoji picker |
| Print or Super+Shift+S | Screenshot |

Some shell files are derived from Caelestia and retain their upstream GPL-3.0
license. The wallpaper picker and other folders may carry their own licenses;
see the license files alongside those components. My configuration files and
scripts are MIT licensed.

## Credits

This rice builds on ideas and configuration from [Caelestia Shell](https://github.com/caelestia-dots/shell), [43PR’s wallpaper picker](https://github.com/43PR/dotfiles/tree/main/.config/quickshell/hyprquickpaper), [JaKooLit Hyprland Dots](https://github.com/JaKooLit/Hyprland-Dots), [HyDE](https://github.com/Hyde-project/hyde), and [ML4W Dotfiles](https://github.com/mylinuxforwork/dotfiles), along with ideas from the r/unixporn community. See the component license files for terms and further credits.
