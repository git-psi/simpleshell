#!/usr/bin/env python3
# "simpleshell" icon theme: Adwaita's, with folders in the accent's hue (their blue moves to the
# accent's hue, lightness kept). Started by apps/theme.sh.
# Usage: folder-icons.py #rrggbb
import colorsys
import os
import re
import subprocess
import sys

SRC = "/usr/share/icons/Adwaita"
DEST = os.path.expanduser("~/.local/share/icons/simpleshell")
BLUE = "#62a0ea"   # main blue of Adwaita's folders, the hue reference


def hls(color):
    return colorsys.rgb_to_hls(*(int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)))


accent = sys.argv[1]
ah, _, as_ = hls(accent)
bh, _, bs = hls(BLUE)


def recolor(match):
    h, l, s = hls(match.group(0))
    # Only the folders' blue colors change (not the grays nor the green trash).
    if s < 0.3 or abs(h - bh) > 0.08:
        return match.group(0)
    r, g, b = colorsys.hls_to_rgb(ah, l, min(1, s * as_ / bs))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


os.makedirs(f"{DEST}/scalable/places", exist_ok=True)
os.makedirs(f"{DEST}/16x16/places", exist_ok=True)
for name in os.listdir(f"{SRC}/scalable/places"):
    if not (name.startswith("folder") or name.startswith("user-")):
        continue
    svg = open(f"{SRC}/scalable/places/{name}").read()
    open(f"{DEST}/scalable/places/{name}", "w").write(re.sub(r"#[0-9a-fA-F]{6}", recolor, svg))

# Small PNG icons: same hue shift (in hundredths of a half-turn for magick).
shift = 100 + ((ah - bh + 0.5) % 1 - 0.5) * 200
for name in os.listdir(f"{SRC}/16x16/places"):
    if name.startswith("folder") or (name.startswith("user-") and name != "user-trash.png"):
        subprocess.run(["magick", f"{SRC}/16x16/places/{name}", "-modulate", f"100,100,{shift:.1f}",
                        f"{DEST}/16x16/places/{name}"], check=False)

open(f"{DEST}/index.theme", "w").write("""[Icon Theme]
Name=simpleshell
Comment=Adwaita, with folders in simpleshell's accent color
Inherits=Adwaita,AdwaitaLegacy,hicolor
Directories=16x16/places,scalable/places

[16x16/places]
Context=Places
Size=16
Type=Fixed

[scalable/places]
Context=Places
Size=128
MinSize=8
MaxSize=512
Type=Scalable
""")
# GTK apps reload the theme when the folder's date changes.
os.utime(DEST)
