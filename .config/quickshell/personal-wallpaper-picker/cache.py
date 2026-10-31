#!/usr/bin/env python3
"""Prepare picker thumbnails without changing the selected wallpaper."""
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
video = {".mp4", ".mkv", ".webm", ".mov"}
images = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp"}
for path in wallpapers.iterdir():
    if not path.is_file() or path.suffix.lower() not in video | images:
        continue
    output = cache / (path.name + ".png")
    if output.exists() and output.stat().st_mtime >= path.stat().st_mtime:
        continue
    temporary = cache / (path.name + ".next.png")
    key = hashlib.sha256(str(path).encode()).hexdigest()
    existing = Path.home() / ".cache/viegphunt/wallpaper-thumbnails" / (key + ".png")
    if existing.exists() and existing.stat().st_mtime >= path.stat().st_mtime:
        source = existing
    elif path.suffix.lower() in video:
        subprocess.run(["ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error", "-y",
                        "-ss", "1", "-i", str(path), "-frames:v", "1", "-vf", "scale=-2:500",
                        "-update", "1", str(temporary)], check=True)
        temporary.replace(output)
        continue
    else:
        source = path
    subprocess.run(["magick", str(source) + "[0]", "-thumbnail", "x500>", "-strip", str(temporary)], check=True)
    temporary.replace(output)
