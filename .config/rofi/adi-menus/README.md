# Desktop menus

Adapted 2026-11-05 from Aditya Shakya (adi1090x), Rofi Type-2 Style-2:
https://github.com/adi1090x/rofi/blob/master/files/launchers/type-2/style-2.rasi
GPL-3.0 license included. The unmodified downloaded theme is retained as
upstream-type-2-style-2.rasi. Local changes remove the app launcher mode and add
shared Catppuccin colors, local fonts and three task-specific layouts.

Super+. opens an emoji grid; Enter copies the emoji for pasting.
Super+V opens clipboard history; Escape leaves the clipboard unchanged.
Super+H opens searchable shortcut hints.
Super+A remains the Caelestia application launcher.
Alt+Space and Super+R are unassigned; the old app_launcher.sh was removed.

Rofi is retained as the on-demand renderer for these menus. No new services
or background processes were added. Each menu uses -no-config and its own theme.
