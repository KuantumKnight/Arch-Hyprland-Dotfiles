#!/usr/bin/env python3
"""Prepare picker thumbnails without changing the selected wallpaper."""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

config = json.loads(Path(sys.argv[1]).read_text())
wallpapers = Path(os.path.expandvars(config["wallpaper_path"]))
cache = Path(os.path.expandvars(config["cache_path"]))
cache.mkdir(parents=True, exist_ok=True)
lock = (cache / ".lock").open("w")
try:
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
    sys.exit(0)

video = {".mp4", ".mkv", ".webm", ".mov"}
images = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp"}
if not wallpapers.is_dir():
    sys.exit(0)
for path in sorted(wallpapers.iterdir()):
    if not path.is_file() or path.suffix.lower() not in video | images:
        continue
    output = cache / (path.name + ".png")
    if output.exists() and output.stat().st_mtime >= path.stat().st_mtime:
        continue
    temporary = cache / (path.name + ".next.png")
    key = hashlib.sha256(str(path).encode()).hexdigest()
    existing = Path.home() / ".cache/viegphunt/wallpaper-thumbnails" / (key + ".png")
    try:
        if existing.exists() and existing.stat().st_mtime >= path.stat().st_mtime:
            source = existing
        elif path.suffix.lower() in video:
            subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
                            "-i", str(path), "-frames:v", "1", "-vf", "scale=480:360:force_original_aspect_ratio=decrease",
                            "-update", "1", str(temporary)], check=True)
            temporary.replace(output)
            continue
        else:
            source = path
        subprocess.run(["magick", "-limit", "thread", "2", str(source) + "[0]", "-thumbnail", "480x360>", "-strip", str(temporary)], check=True)
        temporary.replace(output)
    except (subprocess.SubprocessError, OSError) as error:
        print(f"Thumbnail failed for {path.name}: {error}", file=sys.stderr)
