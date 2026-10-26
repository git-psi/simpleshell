#!/usr/bin/env python3
# Notification of a screenshot or a recording (capture/capture.sh): preview, click or "Open" to open
# it, "Show in folder", "Delete" (to the trash). Stays until the notification is closed.
# Usage: notify.py image|video FILE
import os
import subprocess
import sys

import dbus
import dbus.mainloop.glib
from gi.repository import GLib

kind, path = sys.argv[1:]
name = os.path.basename(path)

# Recording: a frame of the video as the preview, kept with the notification in the history.
preview = path
if kind == "video":
    cache = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"),
                         "simpleshell", "thumbnails")
    os.makedirs(cache, exist_ok=True)
    preview = os.path.join(cache, os.path.splitext(name)[0] + ".jpg")
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", path,
                    "-vf", "thumbnail,scale=640:-2", "-frames:v", "1", preview])
    if not os.path.exists(preview):
        preview = ""

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
session = dbus.SessionBus()
NOTIFS = "org.freedesktop.Notifications"
server = dbus.Interface(session.get_object(NOTIFS, "/org/freedesktop/Notifications"), NOTIFS)

app, icon, summary = {
    "image": ("Screenshot", "lucide:camera", "Screenshot saved"),
    "video": ("Screen recording", "lucide:video", "Recording saved"),
}[kind]
buttons = ["default", "Open", "open", "Open", "folder", "Show in folder", "delete", "Delete"]
# Delete leaves the notification panel open (services/Notifs.qml).
hints = {"x-simpleshell-keep-open": "delete"}
if preview:
    hints["image-path"] = preview
nid = int(server.Notify(app, dbus.UInt32(0), icon, summary, f"Copied to clipboard - {name}",
                        buttons, dbus.Dictionary(hints, signature="sv"), -1))
loop = GLib.MainLoop()


def action(id_, key):
    if int(id_) != nid:
        return
    if key in ("default", "open"):
        subprocess.Popen(["xdg-open", path], start_new_session=True)
    elif key == "folder":
        fm = session.get_object("org.freedesktop.FileManager1", "/org/freedesktop/FileManager1")
        dbus.Interface(fm, "org.freedesktop.FileManager1").ShowItems(["file://" + path], "")
    elif key == "delete":
        subprocess.run(["gio", "trash", path])
        if preview != path and preview:
            os.remove(preview)


def closed(id_, reason):
    if int(id_) == nid:
        loop.quit()


session.add_signal_receiver(action, "ActionInvoked", NOTIFS)
session.add_signal_receiver(closed, "NotificationClosed", NOTIFS)
# The shell restarted: this notification is gone with it.
session.add_signal_receiver(lambda name, old, new: loop.quit(), "NameOwnerChanged",
                            "org.freedesktop.DBus", arg0=NOTIFS)
loop.run()
