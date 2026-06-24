#!/usr/bin/env python3
import json
import os
import subprocess

os.environ["XDG_RUNTIME_DIR"] = "/run/user/1000"

CACHE = os.path.expanduser("~/.cache/eww-notifications.json")
SLOTS = ["notif_0", "notif_1", "notif_2", "notif_3", "notif_4"]

if not os.path.exists(CACHE) or os.path.getsize(CACHE) == 0:
    subprocess.run(["eww", "update", *[f"{s}=" for s in SLOTS]])
    exit(0)

with open(CACHE) as f:
    notifs = json.load(f)

args = []
for i in range(5):
    if i < len(notifs):
        args.append(f"{SLOTS[i]}={json.dumps(notifs[i])}")
    else:
        args.append(f"{SLOTS[i]}=")
subprocess.run(["eww", "update", *args])
