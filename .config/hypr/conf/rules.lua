hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({ name = "xwayland-float-no-blur", match = { xwayland = true, float = true }, no_blur = true })
for _, namespace in ipairs({ "waybar", "logout_dialog", "swaync-control-center", "swaync-notification-window" }) do
    hl.layer_rule({ name = "blur-" .. namespace, match = { namespace = namespace }, blur = true })
end
for _, namespace in ipairs({ "swaync-control-center", "swaync-notification-window" }) do
    hl.layer_rule({ name = "alpha-" .. namespace, match = { namespace = namespace }, ignore_alpha = 0.5 })
end
for i = 1, 10 do
    hl.workspace_rule({ workspace = tostring(i) })
end

-- Hide the active border when a workspace contains only one app.
local singleWindowNoBorder = hl.window_rule({
    name = "single-window-no-active-border",
    enabled = false,
    match = { focus = true },
    border_size = 0,
})

-- Fullscreen apps cover the monitor without a focus outline or rounded cutout.
hl.window_rule({
    name = "fullscreen-no-border-or-rounding",
    match = { fullscreen = true },
    border_size = 0,
    rounding = 0,
})

local function updateSingleWindowBorder()
    local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
    singleWindowNoBorder:set_enabled(workspace ~= nil and workspace.windows == 1)
end

for _, event in ipairs({
    "window.open",
    "window.destroy",
    "window.active",
    "window.move_to_workspace",
    "window.fullscreen",
    "window.minimize",
    "workspace.active",
    "workspace.special_active",
}) do
    hl.on(event, updateSingleWindowBorder)
end

updateSingleWindowBorder()
