#!/bin/sh
# simpleshell's screenshots and screen recordings. Started by services/Capture.qml, which freezes the
# screen (grim) and picks the area (capture/RegionPicker.qml).
#   capture.sh shot FROZEN [X Y W H]              crop in the frozen image's pixels
#   capture.sh window ID                          one window alone (Hyprland stableId)
#   capture.sh record AUDIO(0|1) WF-RECORDER-AREA   -o OUTPUT, or -g "X,Y WxH"
# Screenshots: PNG in Pictures/Screenshots, copied to the clipboard. Recordings: MP4 in
# Videos/Recordings, the file copied to the clipboard (paste it in a file manager or a chat).
# Both end with a notification (capture/notify.py): preview, Open, Show in folder, Delete.
# Recording: prints "recording" once started, stops cleanly on SIGTERM (or SIGINT).
here=$(dirname "$(readlink -f "$0")")
action=$1
shift

# XDG folders (Images, Vidéos… in other languages); xdg-user-dir answers $HOME when unset.
folder() {
    d=$(xdg-user-dir "$1" 2>/dev/null)
    if [ -z "$d" ] || [ "$d" = "$HOME" ]; then d=$HOME/$2; fi
    echo "$d"
}
stamp=$(date +%Y-%m-%d-%H-%M-%S)

case $action in
shot|window)
    dir=$(folder PICTURES Pictures)/Screenshots
    mkdir -p "$dir"
    file=$dir/Screenshot_$stamp.png
    # -quality 31 / -l 3: light compression, three times faster for nearly the same size.
    if [ "$action" = window ]; then
        # The window's own picture (ext-image-copy-capture): nothing on top of it.
        grim -l 3 -T "$1" "$file"
    elif [ $# -eq 5 ]; then
        magick "$1" -crop "$4x$5+$2+$3" +repage -quality 31 "$file"
    else
        magick "$1" -quality 31 "$file"
    fi
    [ -s "$file" ] || exit 1
    wl-copy --type image/png < "$file"
    exec python3 "$here/notify.py" image "$file"
    ;;
record)
    audio=$1
    shift
    dir=$(folder VIDEOS Videos)/Recordings
    mkdir -p "$dir"
    file=$dir/Recording_$stamp.mp4
    # Sound: what the speakers play (monitor of the default output).
    [ "$audio" = 1 ] && set -- "$@" --audio="$(pactl get-default-sink).monitor"
    wf-recorder "$@" -f "$file" -x yuv420p </dev/null >/dev/null 2>&1 &
    pid=$!
    trap 'kill -TERM $pid 2>/dev/null' INT TERM
    echo recording
    wait $pid
    wait $pid 2>/dev/null   # again after a signal: the file is finished only when wf-recorder exits
    [ -s "$file" ] || exit 1
    printf 'file://%s\n' "$file" | wl-copy --type text/uri-list
    # The shell knows the recording is over when this script ends: the notification lives on its own.
    setsid -f python3 "$here/notify.py" video "$file" >/dev/null 2>&1
    ;;
esac
