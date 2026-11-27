# Tinted Glass for Firefox — v5.3.0

Browser chrome CSS, transparent new-tab pages, and optional website glass for
Firefox on a transparency-capable desktop. Hyprland supplies the desktop blur.
This is the existing dotfiles integration, not a standalone browser extension.
Dark Reader and uBlock Origin are installed separately.

## Browser CSS installation

Find the **Root Directory** of your usual profile in `about:profiles`, close
Firefox, and run after the main dotfiles installer:

```bash
python ~/.config/firefox-glass/apply-profile.py /path/to/profile-root
```

This replaces the profile's two rice CSS files after backing them up and merges
only the managed `user.js` block. Existing files are saved under
`~/.local/state/firefox-glass/profile-*`. Restart Firefox afterward.
Tabliss matching is resolved for the selected profile; when Tabliss is absent,
its extension-only selectors are omitted. No personal extension UUID is bundled.

The browser CSS enables the transparent content surface and removes both the
custom toolbar separator and the page-container top border that could leave a
thin colored line above every website. Browser chrome/new-tab glass does not
require the optional website script.

The bundled Hyprland rule is `.config/hypr/conf/firefox_glass.lua`. It keeps the
whole-window opacity at 1.0 so text and controls stay opaque while the page
backgrounds provide transparency. The active Firefox theme supplies the header
image. The portable Super+M binding uses `firefox`; select the intended default
profile in Firefox instead of hard-coding another user's profile path.

## Optional website glass through uBlock Origin

`install.py` registers `knight-glass.js` as a managed uBlock resource and updates
only the managed filter block. It preserves unrelated hidden settings, filters,
and resource URLs, saves a settings snapshot first, and returns to the tab that
was selected when installation started. Snapshots are stored under
`~/.local/state/firefox-glass/install-*.json` and must remain private.

This advanced integration is separate from `install.sh` and `apply-profile.py`.
It requires desktop Firefox with uBlock Origin and a temporary privileged
Marionette session on localhost port 2828. Current Firefox builds require
`MOZ_REMOTE_ALLOW_SYSTEM_ACCESS=1` for privileged browser access. With the
intended profile running in that temporary session, use:

```bash
python ~/.config/firefox-glass/install.py
```

`FIREFOX_MARIONETTE_PORT` selects a different local port if your temporary
session uses one. No debugging preferences are included in the bundled
`user.js`. Remove temporary Marionette/system access and restart Firefox normally
after installation; ordinary browsing does not need it. Internal uBlock/browser
APIs may require maintenance after browser or extension updates.

Re-run this installer after changing the source script: uBlock stores an embedded
copy, so editing `knight-glass.js` alone does not update an existing installation.
Apply the CSS again when the browser styling templates change.

## Website behavior

- Dark pages share a black canvas starting at 88% opacity. A contrast guard can
  strengthen the backing, up to opaque, for faint text. Foregrounds are preserved.
- Light pages use a clear canvas with no white tint. Fully clear pages depend on
  the desktop background for readability; dark mode is recommended.
- Matching nested backgrounds share one canvas rather than stacking tints. Large
  application wrappers and translucent body backgrounds are handled separately
  from cards and overlays.
- Cards, tooltips, menus, table cells, controls, links, code editors and editable
  fields keep their styling. Fixed/sticky page surfaces retain strong backing so
  scrolled text does not bleed through them. Images and videos are not recolored.
- CSS `color(srgb ...)` and other browser-supported modern colors are converted
  before surface classification. This fixes opaque signed-in GitHub dashboard
  feeds. The obsolete GitHub-only root override is no longer included.
- Hidden/open/theme changes are observed; text-only counters avoid full rescans.
  Removed stylesheets and replaced HTML roots can recover. Scrolling alone does
  not trigger rebuilding.
- ChatGPT (`chatgpt.com`, `chat.openai.com`) and YouTube, including subdomains, are
  excluded from website glass. Tabliss retains its separate 32% dark tint.

`data-knight-glass-version`, `data-knight-glass-palette`, and
`data-knight-glass-alpha` on the document root expose the active version,
palette source, and backing strength. The stylesheet uses the `stylus` class so
compatible Dark Reader versions leave its background rules alone. A scoped user
stylesheet allows the managed root color to override protected root backgrounds.

## Recommended Dark Reader setup

Enable Dark Reader in Dynamic dark mode, with brightness 100%, contrast 110%,
sepia 0%, and grayscale 0%. The tested dark palette uses background `#181a1b`
and text `#e8e6e3`. Disable scheduled switching if dark mode should stay enabled.
The installer does not modify Dark Reader settings. Add ChatGPT to Dark Reader's
exclusions as well if it should keep its default appearance.

Reddit's included CSS fallback uses 96% black backing for `.theme-dark` and a
clear canvas for `.theme-light`. It allows glass when Reddit is trusted in
uBlock without changing that trust setting. It depends on Reddit's native theme
classes and does not attempt to rewrite shadow-root interiors.

## Verification and limits

The live setup was checked on popular public sites and with native/Dark Reader
fixtures for theme changes, text contrast, protected controls, nested scrolling,
lazy content, and stylesheet/root recovery. The signed-in GitHub dashboard was
also checked in a fresh window launched by the usual Firefox command: its main
feed became transparent and stayed so after scrolling. The content-edge line
was checked in a desktop capture after a normal Firefox restart.

These are representative checks, not a guarantee for every site or platform.
Complex images, alternate colored sections, media, iframes and shadow DOM may
retain opaque surfaces. Original low-contrast text is not forced to meet a new
contrast target. Large pages can incur a visible rebuild delay; updates are
throttled. Toolbar CSS and browser transparency preferences are Firefox/version
and platform dependent, and desktop blur needs compositor support.
