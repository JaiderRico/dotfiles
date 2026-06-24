#!/usr/bin/env python3
import json
import os
import re
import html
import subprocess
from datetime import datetime

os.environ["XDG_RUNTIME_DIR"] = "/run/user/1000"

CACHE = os.path.expanduser("~/.cache/eww-notifications.json")
MAX = 5
SLOTS = ["notif_0", "notif_1", "notif_2", "notif_3", "notif_4"]

def clean(text):
    text = html.unescape(text)
    text = re.sub("<[^>]+>", "", text)
    return text.strip()

ts = os.environ.get("SWAYNC_TIME", "")
if ts and ts.isdigit():
    t = datetime.fromtimestamp(int(ts)).strftime("%H:%M")
else:
    t = datetime.now().strftime("%H:%M")

app = clean(os.environ.get("SWAYNC_APP_NAME", ""))
if app.lower() == "notify-send":
    app = ""

notifs = []
if os.path.exists(CACHE):
    try:
        with open(CACHE) as f:
            notifs = json.load(f)
    except Exception:
        notifs = []

notifs.append({
    "time": t,
    "app": app,
    "title": clean(os.environ.get("SWAYNC_SUMMARY", "")),
    "body": clean(os.environ.get("SWAYNC_BODY", ""))
})

notifs = notifs[-MAX:]

os.makedirs(os.path.dirname(CACHE), exist_ok=True)
with open(CACHE, "w") as f:
    json.dump(notifs, f, ensure_ascii=False)

args = []
for i in range(5):
    if i < len(notifs):
        args.append(f"{SLOTS[i]}={json.dumps(notifs[i])}")
    else:
        args.append(f"{SLOTS[i]}=")
subprocess.run(["eww", "update", *args])
