#!/usr/bin/env python3
import os
import json
import socket
import subprocess
import sys

SOCKET_PATH = f"{os.environ.get('XDG_RUNTIME_DIR', '/run/user/1000')}/hypr/{os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')}/.socket2.sock"
PANEL_CLASSES = {"swaync", "rofi", "Eww", "eww"}

def call_hyprctl(command):
    try:
        return subprocess.run(
            ["hyprctl", "-j"] + command.split(),
            capture_output=True, text=True, timeout=2
        ).stdout.strip()
    except Exception:
        return ""

def get_focused_class():
    out = call_hyprctl("activewindow")
    if not out:
        return ""
    try:
        return json.loads(out).get("class", "")
    except (json.JSONDecodeError, AttributeError):
        return ""

def close_panels():
    subprocess.run(["swaync-client", "-cp"], capture_output=True)
    subprocess.run(["eww", "close", "calendar_popup"], capture_output=True)

def main():
    if not os.path.exists(SOCKET_PATH):
        print("Hyprland socket not found", file=sys.stderr)
        sys.exit(1)

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(SOCKET_PATH)
    sock.sendall(b"windowfocus\n")
    sock.shutdown(socket.SHUT_WR)

    buf = b""
    while True:
        chunk = sock.recv(4096)
        if not chunk:
            break
        buf += chunk
        while b"\n" in buf:
            line, buf = buf.split(b"\n", 1)
            event = line.decode().strip()
            if event.startswith("windowfocus>>"):
                focused = get_focused_class()
                if focused and focused not in PANEL_CLASSES:
                    close_panels()

if __name__ == "__main__":
    main()
