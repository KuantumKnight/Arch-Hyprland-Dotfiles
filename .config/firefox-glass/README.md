# Firefox glass

## Browser CSS installation

After the main dotfiles installer, close Firefox and run:

```bash
python ~/.config/firefox-glass/apply-profile.py /path/to/profile-root
```

Find the profile root in `about:profiles`. This replaces the profile's two rice
CSS files after saving backups, and merges only the managed `user.js` block.
Restart Firefox afterward. Tabliss extension matching is resolved per profile;
without Tabliss the ordinary new-tab rules still apply.

## Optional website glass

The following describes the existing website-glass integration. It is separate
from browser CSS and is not run by `install.sh` or `apply-profile.py`.
`install.py` requires desktop Firefox with uBlock Origin and a temporarily
available privileged Marionette connection on localhost port 2828. It adds a
managed script resource and filter through uBlock's API and saves existing
settings first. It uses internal extension/browser APIs and can need updates
when those change. Run it only after preparing that temporary connection, then
remove privileged remote access and restart Firefox. Normal browsing needs no
Marionette connection. No browser remote-access preference is bundled.

### Dark Reader-compatible Firefox glass 4.2.0

Dark Reader owns all colour decisions. This script only adjusts alpha on eligible
neutral background surfaces, preserving their resolved RGB values. Foregrounds,
buttons, accents, SVGs and image fixes remain as Dark Reader renders them.
Dark surfaces start at 65% opacity; native light surfaces start at 80%. Contrast
checks can increase opacity or leave individual surfaces unchanged.

The script uses one managed stylesheet carrying the stylus class, which the
installed Dark Reader 4.9.135 excludes from stylesheet transformation. Surface
IDs are attributes rather than inline background edits. A narrowly scoped user
stylesheet allows the root background alpha to override Dark Reader's protected
root background; it only applies while the script marks that root. Native and
Dark Reader palettes are re-read with our own stylesheet disabled. Own changes
are ignored by the observer; page/theme updates are coalesced. Filter modes and
unsupported effects remain unmodified. Large/complex pages may keep opaque areas.

ChatGPT (chatgpt.com and chat.openai.com) and YouTube, including their subdomains,
are excluded from all custom glass. Its top bar uses
the regular website/Dark Reader appearance, without our blur, tint or highlights.
Tabliss keeps its separate 32% tint.

The document markers data-knight-glass-version and data-knight-glass-palette
identify the installed version and palette source (darkreader or native).
install.py preserves current uBlock settings/filters and updates only the managed
resource/filter block. Settings snapshots and previous code are stored under
~/.local/state/firefox-glass. Installation requires temporary Marionette system
access, which must be removed afterward. No extra addon or service is installed.

Previous live-setup tests used the actual Dark Reader extension in an isolated Firefox profile:
RGB/foreground/button/SVG preservation, translucent root, idle-loop check, and
disabling/re-enabling Dark Reader across reloads. Production verification checked
the installed version and confirmed YouTube receives no stylesheet or marker.
