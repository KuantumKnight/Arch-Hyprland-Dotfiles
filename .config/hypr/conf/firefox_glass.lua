-- Firefox stays opaque; selected page backgrounds use CSS transparency.
hl.window_rule({
    name = "firefox-liquid-glass",
    match = { class = "^[Ff]irefox$" },
    opacity = "1.0 override 1.0 override 1.0 override",
    no_blur = false,
    opaque = false,
    xray = false,
})
hl.window_rule({
    name = "firefox-glass-square",
    match = { class = "^[Ff]irefox$", fullscreen = false },
    rounding = 0,
})
