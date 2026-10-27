#!/bin/sh
# simpleshell's sleep: shows the SDDM login screen and locks the session, without closing it. Logging
# back in, SDDM reopens it (ReuseSession); hypridle then closes hyprlock (unlock_cmd →
# power/unlock.sh). Started by the Sleep button (Config.qml), the idle lock and before suspend
# (hypridle).

# Already on SDDM (sleep started from the login screen): the session is already locked.
[ "$(loginctl show-session auto -p Active --value)" = yes ] || exit 0

# Lock first: started on a session already left (SDDM shown), hyprlock gets stuck (Hyprland no
# longer draws, the lock is never confirmed) and doesn't close on return.
# It's still needed, otherwise Ctrl+Alt+F1 from SDDM would reopen the session without a password.
# Hidden lock (black screen, hypr/hyprlock-hidden.conf): the regular one would flash by. Already
# locked (Lock, then Sleep): kept as is.
pidof hyprlock >/dev/null || setsid -f hyprlock -c "$(dirname "$(readlink -f "$0")")/../hypr/hyprlock-hidden.conf"
i=0
until pidof hyprlock >/dev/null || [ $i -ge 30 ]; do sleep 0.1; i=$((i + 1)); done
sleep 1   # let hyprlock lock the screens

busctl --system call org.freedesktop.DisplayManager /org/freedesktop/DisplayManager/Seat0 \
    org.freedesktop.DisplayManager.Seat SwitchToGreeter
