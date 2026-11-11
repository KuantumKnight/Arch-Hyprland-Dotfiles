# Arch Hyprland Dotfiles

My Arch Linux Hyprland rice: a Lua-based Hyprland setup, a customized
Caelestia shell, and a fast wallpaper carousel with parallax and live wallpaper support.
It grew out of a mix of other rices and my own changes. The configs are tuned
for my setup, so review the keybindings and settings before applying them.

## Video showcase

<video src="https://github.com/KuantumKnight/Arch-Hyprland-Dotfiles/releases/download/v1.0.0/showcase.mp4" controls playsinline width="100%"></video>

[Download the full live screen recording (MP4)](media/showcase.mp4) or [get it from the v1.0.0 release](https://github.com/KuantumKnight/Arch-Hyprland-Dotfiles/releases/download/v1.0.0/showcase.mp4).

## What’s included

- Hyprland Lua settings, bindings, window rules, and startup hooks
- Customized Caelestia shell and settings
- Kitty, GTK, and CAVA configuration
- Bash with Starship prompt and a Fastfetch startup image
- Matching adi1090x-style emoji, clipboard, and searchable shortcut menus
- Nine-card wallpaper carousel with smooth selection magnification and strong image parallax
- Background thumbnail caching and muted, looping live wallpaper playback
- Small launcher and desktop helper scripts
- Spotify window transparency through a Hyprland rule

Five sample wallpapers are included and copied to `~/Pictures/Wallpapers`
when their filenames are not already present. See [WALLPAPERS.md](WALLPAPERS.md)
for their Wallhaven source links and third-party attribution notes. You can
add more images or videos to that directory at any time. The AWCC integration is
optional and disabled by default; it requires a separate Alienware GUI
installation.

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

After installation, log out and start Hyprland again. The bundled images are
available in `~/Pictures/Wallpapers`; add your own images or videos there and choose one
with **Super+W**.

## Shell and prompt

Kitty launches Bash with the bundled `.bashrc` and Starship prompt. The installer
installs Bash, bash-completion, Starship, and Fastfetch, and backs up any existing
`.bashrc`, Starship configs, and Fastfetch directory before replacing them.
Your account's login shell is unchanged.

The prompt uses Starship defaults outside your home directory. At home it shows
`user@host` and hides the Python module. Fastfetch shows the bundled character
image in the first Kitty window when only one Kitty instance is running.
Customize `.config/starship.toml`, `.config/starship-home.toml`, and
`.config/fastfetch/config.jsonc` to change the appearance. The Fastfetch image is
bundled separately from the MIT-licensed configuration files.

## Wallpaper carousel

The selected card is largest, its immediate neighbors are slightly enlarged, and
all other cards stay compact. Magnification follows the selection at both ends.
Images pan inside their cards as you browse. There is no white selection outline.
Arrows, A/D and the scroll wheel browse; Enter or clicking applies; Escape closes.

Supported files: PNG, JPG, JPEG, WebP, BMP, GIF, MP4, MKV, WebM and MOV.
Video thumbnails are still images with a LIVE badge, so browsing does not start
video players. Thumbnails prepare in the background. Only the applied live
wallpaper runs through mpvpaper, muted and looping, requesting hardware decoding
and pausing when hidden. Selecting a still stops live playback.

Rofi is retained only for the on-demand emoji, clipboard and shortcut menus.
Their themes are adapted from adi1090x Type-2 Style-2; they add no background service.

## Keybindings

| Shortcut | Action |
| --- | --- |
| Super+H | Show key hints |
| Super+K / Super+E | Kitty / Nemo |
| Super+M | Firefox |
| Super+A / D / N / X | Caelestia launcher / dashboard / sidebar / session menu |
| Alt+Space / Super+R | Unassigned; use Super+A for apps |
| Super+W / Super+Shift+W | Choose / randomize wallpaper |
| Super+Q / Super+Shift+Q | Close / force close window |
| Super+L | Lock screen |
| Super+V / Super+. | Styled clipboard history / emoji grid (Enter copies) |
| Print or Super+Shift+S | Screenshot |

Some shell files are derived from Caelestia and retain their upstream GPL-3.0
license. The wallpaper picker and other folders may carry their own licenses;
see the license files alongside those components. My original configuration files and
scripts are MIT licensed; the adapted adi1090x menu themes retain GPL-3.0.
The third-party wallpaper images have separate source and attribution notes in
[WALLPAPERS.md](WALLPAPERS.md) and are not covered by the repository's MIT license.

## Credits

This rice builds on [adi1090x’s Rofi themes](https://github.com/adi1090x/rofi), configuration adapted from [ViegPhunt](https://github.com/ViegPhunt/Arch-Hyprland), and ideas and configuration from [Caelestia Shell](https://github.com/caelestia-dots/shell), [43PR’s wallpaper picker](https://github.com/43PR/dotfiles/tree/main/.config/quickshell/hyprquickpaper), [JaKooLit Hyprland Dots](https://github.com/JaKooLit/Hyprland-Dots), [HyDE](https://github.com/Hyde-project/hyde), and [ML4W Dotfiles](https://github.com/mylinuxforwork/dotfiles), along with ideas from the r/unixporn community. See the component license files for terms and further credits.
