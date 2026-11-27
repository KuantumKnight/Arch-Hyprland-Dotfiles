#!/usr/bin/env python3
"""Install only rice CSS and managed preferences into an explicit Firefox profile."""
import argparse
import datetime
import json
from pathlib import Path
import re
import shutil


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('profile', type=Path, help='Profile root from Firefox about:profiles; close Firefox first')
    args = parser.parse_args()
    profile = args.profile.expanduser().resolve()
    if not (profile / 'prefs.js').is_file():
        parser.error('Expected an existing Firefox profile containing prefs.js')
    source = Path(__file__).resolve().parent
    prefs = (profile / 'prefs.js').read_text()
    match = re.search(r'user_pref\("extensions.webextensions.uuids",\s*("(?:\\.|[^"\\])*")\);', prefs)
    uuids = json.loads(json.loads(match[1])) if match else {}
    tabliss = uuids.get('extension@tabliss.io')
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup = Path.home() / '.local/state/firefox-glass' / ('profile-' + stamp)
    backup.mkdir(parents=True)
    (profile / 'chrome').mkdir(exist_ok=True)
    for name in ['userChrome.css', 'userContent.css']:
        target = profile / 'chrome' / name
        if target.exists():
            shutil.copy2(target, backup / name)
        css = (source / 'chrome' / name).read_text()
        # Extension UUIDs vary between profiles. Omit Tabliss-only matching if absent.
        css = css.replace('url-prefix("moz-extension://TABLISS_UUID/"), ',
                          f'url-prefix("moz-extension://{tabliss}/"), ' if tabliss else '')
        target.write_text(css)
    target = profile / 'user.js'
    text = target.read_text() if target.exists() else ''
    if target.exists():
        shutil.copy2(target, backup / 'user.js')
    text = re.sub(r'// BEGIN KNIGHT LIQUID GLASS\n.*?// END KNIGHT LIQUID GLASS\n?', '', text, flags=re.S)
    target.write_text(text.rstrip() + '\n\n' + (source / 'user.js').read_text())
    print(f'Installed Firefox rice. Previous files: {backup}')
    print('Restart Firefox. Website glass through uBlock is a separate optional step.')


if __name__ == '__main__':
    main()
