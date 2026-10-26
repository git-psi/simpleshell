#!/usr/bin/env python3
# BlueZ pairing agent for simpleshell (Quickshell doesn't provide one: without an agent, pairings
# that need a confirmation fail).
# Talks to the shell with JSON lines on stdout; the shell answers "yes" or "no" on stdin.
#   {"type": "confirm", "address", "name", "passkey"}  code to compare ("" = simple consent)
#   {"type": "display", "address", "name", "passkey"}  code to type on the device
#   {"type": "cancel"}                                  the request was cancelled
import json
import sys

import dbus
import dbus.mainloop.glib
import dbus.service
from gi.repository import GLib

BUS = "org.bluez"
PATH = "/simpleshell/agent"
IFACE = "org.bluez.Agent1"


class Rejected(dbus.DBusException):
    _dbus_error_name = "org.bluez.Error.Rejected"


class Canceled(dbus.DBusException):
    _dbus_error_name = "org.bluez.Error.Canceled"


def send(**msg):
    print(json.dumps(msg), flush=True)


def device(path):
    try:
        props = dbus.Interface(bus.get_object(BUS, path), "org.freedesktop.DBus.Properties")
        p = props.GetAll("org.bluez.Device1")
    except dbus.DBusException:
        return {}
    return p


class Agent(dbus.service.Object):
    pending = None  # (success, failure) of the pending confirmation

    def ask(self, kind, path, passkey, ok=None, err=None):
        if self.pending:
            self.pending[1](Canceled())
        self.pending = (ok, err) if ok else None
        p = device(path)
        send(type=kind, address=str(p.get("Address", "")),
             name=str(p.get("Alias", p.get("Name", ""))), passkey=passkey)

    def answer(self, yes):
        if not self.pending:
            return
        ok, err = self.pending
        self.pending = None
        ok() if yes else err(Rejected())

    @dbus.service.method(IFACE, in_signature="", out_signature="")
    def Release(self):
        pass

    # An already paired or trusted device may use its services without asking.
    @dbus.service.method(IFACE, in_signature="os", out_signature="")
    def AuthorizeService(self, path, uuid):
        p = device(path)
        if not (p.get("Paired") or p.get("Trusted")):
            raise Rejected()

    # Old devices with a fixed code (headsets, cars): the code is almost always 0000.
    @dbus.service.method(IFACE, in_signature="o", out_signature="s")
    def RequestPinCode(self, path):
        return "0000"

    @dbus.service.method(IFACE, in_signature="os", out_signature="")
    def DisplayPinCode(self, path, pincode):
        self.ask("display", path, str(pincode))

    @dbus.service.method(IFACE, in_signature="o", out_signature="u")
    def RequestPasskey(self, path):
        raise Rejected()

    # Keyboards: the code is shown, typed on the keyboard, then Enter.
    @dbus.service.method(IFACE, in_signature="ouq", out_signature="")
    def DisplayPasskey(self, path, passkey, entered):
        if entered == 0:
            self.ask("display", path, "%06d" % passkey)

    @dbus.service.method(IFACE, in_signature="ou", out_signature="",
                         async_callbacks=("ok", "err"))
    def RequestConfirmation(self, path, passkey, ok, err):
        self.ask("confirm", path, "%06d" % passkey, ok, err)

    @dbus.service.method(IFACE, in_signature="o", out_signature="",
                         async_callbacks=("ok", "err"))
    def RequestAuthorization(self, path, ok, err):
        self.ask("confirm", path, "", ok, err)

    @dbus.service.method(IFACE, in_signature="", out_signature="")
    def Cancel(self):
        if self.pending:
            self.pending[1](Canceled())
            self.pending = None
        send(type="cancel")


def register(owner):
    # Called at startup and every time bluetoothd restarts.
    if not owner:
        return
    manager = dbus.Interface(bus.get_object(BUS, "/org/bluez"), "org.bluez.AgentManager1")
    try:
        manager.RegisterAgent(PATH, "DisplayYesNo")
    except dbus.DBusException:
        pass  # already registered
    try:
        manager.RequestDefaultAgent(PATH)
    except dbus.DBusException as e:
        print("simpleshell bt-agent:", e, file=sys.stderr, flush=True)


def on_input(source, condition):
    line = sys.stdin.readline()
    if not line:  # the shell stopped
        loop.quit()
        return False
    agent.answer(line.strip() == "yes")
    return True


dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus = dbus.SystemBus()
agent = Agent(bus, PATH)
bus.watch_name_owner(BUS, register)
GLib.io_add_watch(sys.stdin, GLib.IO_IN | GLib.IO_HUP, on_input)
loop = GLib.MainLoop()
loop.run()
