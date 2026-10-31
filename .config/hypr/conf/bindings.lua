local home = os.getenv("HOME")
local scripts = home .. "/.config/viegphunt/"
local function command(key, cmd, opts)
    hl.bind(key, hl.dsp.exec_cmd(cmd), opts)
end

command("SUPER + H", scripts .. "key_hints.sh")
command("SUPER + K", "kitty")
command("SUPER + E", "nemo")
command("SUPER + M", "firefox")
command("CTRL + SHIFT + Escape", "kitty --class=btop --title=btop btop")
hl.bind("SUPER + SHIFT + CTRL + Escape", hl.dsp.exit())
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + Q", hl.dsp.window.kill())
hl.bind("SUPER + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + P", hl.dsp.window.pseudo())
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))
command("SUPER + L", "caelestia shell lock lock")
command("ALT + SPACE", scripts .. "app_launcher.sh")
command("SUPER + R", scripts .. "app_launcher.sh")
command("SUPER + PERIOD", scripts .. "emoji_launcher.sh")
command("SUPER + V", scripts .. "clipboard_launcher.sh")
command("SUPER + A", "caelestia shell drawers toggle launcher")
command("SUPER + D", "caelestia shell drawers toggle dashboard")
command("SUPER + N", "caelestia shell drawers toggle sidebar")
command("SUPER + X", "caelestia shell drawers toggle session")
command("SUPER + W", scripts .. "wallpaper_select.sh")
command("SUPER + SHIFT + W", scripts .. "wallpaper_random.sh")
command("SUPER + SHIFT + S", "flameshot gui -c -p " .. home .. "/Pictures/Screenshots")
command("Print", "flameshot gui -c -p " .. home .. "/Pictures/Screenshots")

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }))
end
for i = 1, 10 do
    local key = i % 10
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

local media = { locked = true, repeating = true }
command("XF86PowerOff", "caelestia shell drawers toggle session", { locked = true })
command("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", media)
command("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", media)
command("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", media)
command("XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", media)
command("XF86MonBrightnessUp", "brightnessctl -e4 -n2 set 10%+", media)
command("XF86MonBrightnessDown", "brightnessctl -e4 -n2 set 10%-", media)
command("XF86AudioNext", "playerctl next", { locked = true })
command("XF86AudioPause", "playerctl play-pause", { locked = true })
command("XF86AudioPlay", "playerctl play-pause", { locked = true })
command("XF86AudioPrev", "playerctl previous", { locked = true })
