#!/usr/bin/env python3
# USB drives for simpleshell: a notification when one is plugged in ("Open" button: mounted through
# UDisks2 if needed, then opened in the file manager) and when it is removed.
# Started by notifs/Usb.qml; only watches drives plugged in after it started.
import os
import subprocess

import dbus
import dbus.mainloop.glib
from gi.repository import GLib

UDISKS = "org.freedesktop.UDisks2"
FS = UDISKS + ".Filesystem"
BLOCK = UDISKS + ".Block"
DRIVE = UDISKS + ".Drive"
PROPS = "org.freedesktop.DBus.Properties"
ICON = "lucide:usb"   # Lucide icon, drawn by NotificationCard

known = {}     # UDisks2 path of the partition → displayed name
shown = {}     # path → id of the "connected" notification
last = {}      # displayed name → id of its last notification (only one per drive in the history)
actions = {}   # notification id → path


def props(path, iface):
    return dbus.Interface(system.get_object(UDISKS, path), PROPS).GetAll(iface)


def size(n):
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1000 or unit == "TB":
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1000


# Notification server (simpleshell) looked up every time: it may have restarted since.
def notifier():
    obj = session.get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications")
    return dbus.Interface(obj, "org.freedesktop.Notifications")


# Replaces this drive's last notification: closed then sent again (a plain replacement wouldn't
# show as a popup).
def notify_key(label, summary, body, buttons=()):
    old = last.pop(label, None)
    if old is not None:
        actions.pop(old, None)
        try:
            notifier().CloseNotification(dbus.UInt32(old))
        except dbus.DBusException:
            pass
    last[label] = notify(summary, body, buttons)
    return last[label]


def notify(summary, body, buttons=(), replaces=0):
    acts = []
    for key, label in buttons:
        acts += [key, label]
    return int(notifier().Notify("USB drive", dbus.UInt32(replaces), ICON, summary, body, acts, {}, -1))


def added(path, ifaces):
    # UDisks2 often announces the partition (Block) then, once probed, its filesystem in a second
    # signal: Block is then read separately.
    if FS not in ifaces or path in known:
        return
    try:
        block = ifaces[BLOCK] if BLOCK in ifaces else props(path, BLOCK)
    except dbus.DBusException:
        return
    if block.get("HintIgnore") or block.get("HintSystem"):
        return
    try:
        drive = props(block["Drive"], DRIVE)
    except dbus.DBusException:
        return
    if drive.get("ConnectionBus") != "usb" and not drive.get("Removable"):
        return
    label = str(block.get("IdLabel") or "") or " ".join(
        str(drive.get(k) or "") for k in ("Vendor", "Model")).strip() or "USB drive"
    known[path] = label
    nid = notify_key(label, "USB drive connected", f"{label} - {size(int(block.get('Size', 0)))}",
                     [("default", "Open"), ("open", "Open")])
    shown[path] = nid
    actions[nid] = path


def removed(path, ifaces):
    if path not in known or (FS not in ifaces and BLOCK not in ifaces):
        return
    label = known.pop(path)
    shown.pop(path, None)
    notify_key(label, "USB drive removed", label)


def open_drive(path):
    fs = dbus.Interface(system.get_object(UDISKS, path), FS)
    try:
        points = props(path, FS).get("MountPoints", [])
        if points:
            where = bytes(points[0]).rstrip(b"\0").decode()
        else:
            where = str(fs.Mount({}, timeout=60))
    except dbus.DBusException as e:
        notify("Couldn't open the drive", e.get_dbus_message() or known.get(path, ""))
        return
    subprocess.Popen(["xdg-open", where], start_new_session=True)


def action(nid, key):
    path = actions.pop(int(nid), None)
    if path and key in ("default", "open"):
        shown.pop(path, None)
        open_drive(path)


dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
system = dbus.SystemBus()
session = dbus.SessionBus()
manager = "org.freedesktop.DBus.ObjectManager"
system.add_signal_receiver(added, "InterfacesAdded", manager, UDISKS)
system.add_signal_receiver(removed, "InterfacesRemoved", manager, UDISKS)
session.add_signal_receiver(action, "ActionInvoked", "org.freedesktop.Notifications")
# Shell stopped (or crashed): stop too, otherwise every restart adds one more.
parent = os.getppid()
GLib.timeout_add_seconds(5, lambda: os.getppid() == parent or os._exit(0))
GLib.MainLoop().run()
