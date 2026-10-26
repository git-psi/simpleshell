#!/bin/sh
# hypridle's unlock_cmd. SDDM unlocks the session (logind) right before switching to it: wait until
# it's shown to close hyprlock, then turn the screens back on.
i=0
until [ "$(loginctl show-session auto -p Active --value)" = yes ] || [ $i -ge 50 ]; do
    sleep 0.2; i=$((i + 1))
done
pkill -USR1 hyprlock
hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })'
