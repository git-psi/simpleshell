#!/usr/bin/env python3
# Prints the content of a sysfs file at startup, then each time the kernel signals a change.
# Usage: sysfs-watch.py FILE [TRIGGER]: FILE is printed when TRIGGER (FILE by default) changes.
# sysfs doesn't go through inotify: it wakes up poll() (POLLPRI), so nothing runs in between,
# unlike reading the file on a timer.
import ctypes
import select
import signal
import sys

# Dies with the shell: otherwise a restart (pkill qs) leaves it behind, sleeping forever.
ctypes.CDLL(None).prctl(1, signal.SIGTERM)   # PR_SET_PDEATHSIG

path = sys.argv[1]
trigger = open(sys.argv[2] if len(sys.argv) > 2 else path, "rb", buffering=0)
poller = select.poll()
poller.register(trigger, select.POLLPRI | select.POLLERR)


def show():
    with open(path) as f:
        print(f.read().strip(), flush=True)


while True:
    trigger.seek(0)
    try:
        trigger.read()   # poll() only reports changes after the file has been read
    except OSError:
        pass             # brightness_hw_changed: no value until the first change
    show()
    poller.poll()
