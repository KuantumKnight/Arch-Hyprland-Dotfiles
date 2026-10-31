-- Use the closest supported scale to a 20% reduction and keep the preferred refresh rate.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "macOS")
hl.env("GDK_BACKEND", "wayland,x11,*")
-- Compensate for the inherited 120-DPI GTK font setting in Hyprland only.
hl.env("GDK_DPI_SCALE", "0.8")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 2,
        col = {
            active_border = "rgba(595959aa)",
            inactive_border = "rgba(59595900)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 0, -- Keep application windows square.
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true, range = 4, render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true, size = 6, passes = 3,
            new_optimizations = true, ignore_opacity = true,
        },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        initial_workspace_tracking = 1,
    },
    ecosystem = { no_update_news = true },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        accel_profile = "flat",
        natural_scroll = false,
        touchpad = { natural_scroll = true, scroll_factor = 0.5 },
    },
    xwayland = { force_zero_scaling = true },
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
