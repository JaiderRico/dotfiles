#!/usr/bin/env python3

import os
import html

CACHE = os.path.expanduser("~/.cache/eww-notifications.txt")
MAX = 5

if not os.path.exists(CACHE) or os.path.getsize(CACHE) == 0:
    print("Sin notificaciones")
    exit(0)

lines = []
with open(CACHE) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        parts = line.split("|", 3)
        if len(parts) >= 4:
            time, app, summary, body = parts
            summary_esc = html.escape(summary)
            body_esc = html.escape(body)
            if len(body_esc) > 60:
                body_esc = body_esc[:57] + "..."
            entry = f"<span color='#9399b2'>{html.escape(time)}</span>  <b>{summary_esc}</b>\n"
            if body_esc:
                entry += f"<span color='#a6adc8'>{body_esc}</span>\n"
            lines.append(entry)

if not lines:
    print("Sin notificaciones")
else:
    print("\n".join(lines[-MAX:]), end="")
