#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
backup_root="$HOME/.local/state/arch-hyprland-dotfiles/backups/$(date +%Y%m%d-%H%M%S)-$$"

pacman_packages=(
  base-devel git hyprlock
  awww brightnessctl bluez bluez-utils blueman cliphist
  btop firefox ffmpeg flameshot imagemagick kitty nemo network-manager
  network-manager-applet
  pipewire pipewire-pulse wireplumber pavucontrol playerctl polkit-kde-agent
  rofi rofi-emoji wl-clipboard python libnotify
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  adw-gtk-theme gtk3 gtk4 gsettings-desktop-schemas noto-fonts
  ttf-jetbrains-mono-nerd noto-fonts-emoji
)
aur_packages=(
  caelestia-cli caelestia-shell quickshell-git qt6-m3shapes-git
  python-materialyoucolor libcava ttf-rubik-vf
  apple_cursor whitesur-icon-theme mpvpaper
)
managed_paths=(
  .config/hypr
  .config/caelestia
  .config/cava
  .config/gtk-3.0
  .config/gtk-4.0
  .config/kitty
  .config/quickshell/caelestia
  .config/quickshell/personal-wallpaper-picker
  .config/rofi
  .config/viegphunt
  .local/bin/awcc-launch
)
managed_units=(
  caelestia-shell.service
  hypr-wallpaper.service
  hypr-wallpaper-poster.service
  hypr-live-wallpaper.service
)

usage() {
  cat <<'USAGE'
Usage: ./install.sh

Installs the Arch Hyprland rice dependencies, backs up managed user configs,
applies this repository's configs, and reloads the user systemd manager.
Run as a regular user, not root. Hyprland must already be installed.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
elif [[ $# -gt 0 ]]; then
  usage >&2
  exit 2
fi

if (( EUID == 0 )); then
  printf 'Run this installer as your regular user, not root.\n' >&2
  exit 1
fi
if [[ ! -e /etc/arch-release ]]; then
  printf 'This installer supports Arch Linux only.\n' >&2
  exit 1
fi
if ! command -v hyprctl >/dev/null 2>&1; then
  printf 'Install Hyprland before applying this rice.\n' >&2
  exit 1
fi
if ! command -v sudo >/dev/null 2>&1; then
  printf 'Install and configure sudo before continuing.\n' >&2
  exit 1
fi

cat <<'NOTICE'
This installs packages and replaces the rice configuration paths listed by
this repository. Existing managed paths are backed up before replacement.
AUR packages will be built on this machine; inspect their PKGBUILDs.
NOTICE
read -r -p 'Continue? [y/N] ' answer
case "$answer" in
  [yY]|[yY][eE][sS]) ;;
  *) printf 'Cancelled.\n'; exit 0 ;;
esac

sudo pacman -Syu --needed "${pacman_packages[@]}"

if ! command -v yay >/dev/null 2>&1; then
  if ! command -v makepkg >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
    printf 'Could not prepare yay; makepkg and git are required.\n' >&2
    exit 1
  fi
  yay_build_dir="$(mktemp -d)"
  trap 'rm -rf -- "$yay_build_dir"' EXIT
  git clone https://aur.archlinux.org/yay.git "$yay_build_dir/yay"
  (cd "$yay_build_dir/yay" && makepkg -si)
  rm -rf -- "$yay_build_dir"
  trap - EXIT
fi

yay -S --needed "${aur_packages[@]}"

mkdir -p "$backup_root"
for relative_path in "${managed_paths[@]}"; do
  source_path="$HOME/$relative_path"
  if [[ -e "$source_path" || -L "$source_path" ]]; then
    backup_path="$backup_root/$relative_path"
    mkdir -p "$(dirname -- "$backup_path")"
    mv -- "$source_path" "$backup_path"
    printf 'Backed up %s\n' "$relative_path"
  fi
done
for unit in "${managed_units[@]}"; do
  source_path="$HOME/.config/systemd/user/$unit"
  if [[ -e "$source_path" || -L "$source_path" ]]; then
    backup_path="$backup_root/.config/systemd/user/$unit"
    mkdir -p "$(dirname -- "$backup_path")"
    mv -- "$source_path" "$backup_path"
    printf 'Backed up .config/systemd/user/%s\n' "$unit"
  fi
done

mkdir -p "$HOME/.config" "$HOME/.config/systemd/user" \
  "$HOME/.config/hypr" "$HOME/Pictures/Wallpapers" "$HOME/.local/bin"
cp -a "$repo_dir/.config/." "$HOME/.config/"
for unit in "${managed_units[@]}"; do
  cp -a "$repo_dir/.config/systemd/user/$unit" "$HOME/.config/systemd/user/"
done
cp -a "$repo_dir/.local/bin/awcc-launch" "$HOME/.local/bin/awcc-launch"
chmod +x "$HOME/.local/bin/awcc-launch"
find "$HOME/.config/viegphunt" "$HOME/.config/quickshell/personal-wallpaper-picker" \
  -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} +
[[ -e "$HOME/.config/hypr/wallpaper" ]] || : > "$HOME/.config/hypr/wallpaper"
systemctl --user daemon-reload

printf '\nInstalled. Backup: %s\n' "$backup_root"
printf 'Log out and start Hyprland again to apply the rice.\n'
