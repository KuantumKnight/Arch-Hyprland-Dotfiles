# Wallpaper carousel

Adapted from https://github.com/43PR/dotfiles/tree/main/.config/quickshell/hyprquickpaper
Source reviewed at 6b5c0c203fee96bff017a0398ea8c0c14591f17a. MIT license included.
Upstream credits the original hyprquickpaper project by iamsurjog.

Uses images and live wallpapers from ~/Pictures/Wallpapers with nine visible
cards, tight spacing, fast scrolling, and background thumbnail preparation.
Super+W toggles the carousel. Arrows, A/D and scrolling browse; Enter or clicking
applies a wallpaper. Esc closes the picker. The selected card is largest, its neighbors are enlarged,
and images pan inside their cards. This also works at the ends of the list.
There is no selection outline.

Supported formats: PNG, JPG, JPEG, WebP, BMP, GIF, MP4, MKV, WebM, MOV.
Browsing uses cached still thumbnails; LIVE badges identify animated files.
No video decoders run in the picker. The selected live wallpaper runs through
hypr-live-wallpaper.service using mpvpaper, muted, looping, with hardware decoding
requested and auto-pause when hidden. Selecting a still image stops that player.
The selected wallpaper restores through hypr-wallpaper.service on login.

config.json controls number_of_pictures (default 9). New thumbnails appear as
they finish in the background. Existing cached thumbnails open immediately.
