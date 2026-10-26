#!/bin/sh
# Screens of the login screen (SDDM runs on X11): every connected screen on, at its preferred
# resolution, side by side. Replaces the Xsetup that Monique rewrites for each profile.
prev=
for out in $(xrandr | awk '/ connected/ { print $1 }'); do
    if [ -z "$prev" ]; then
        xrandr --output "$out" --auto
    else
        xrandr --output "$out" --auto --right-of "$prev"
    fi
    prev=$out
done
