#!/usr/bin/env python3
import os
import json
import socket
import subprocess
import sys
import select

SOCKET_PATH = f"{os.environ.get('XDG_RUNTIME_DIR', '/run/user/1000')}/hypr/{os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')}/.socket2.sock"
PANEL_CLASSES = {"swaync", "rofi", "Eww", "eww"}

def close_all_panels():
    subprocess.run(["swaync-client", "-cp"], capture_output=True, timeout=3)
    result = subprocess.run(
        ["eww", "active-windows"], capture_output=True, text=True, timeout=3
    )
    for win in result.stdout.strip().splitlines():
        if win.strip():
            subprocess.run(["eww", "close", win.strip()], capture_output=True, timeout=3)

def get_active_class():
    try:
        out = subprocess.run(
            ["hyprctl", "-j", "activewindow"],
            capture_output=True, text=True, timeout=3
        ).stdout.strip()
        if not out:
            return ""
        return json.loads(out).get("class", "")
    except Exception:
        return ""

def cursor_inside_any_eww():
    try:
        cx, cy = map(int, subprocess.run(
            ["hyprctl", "cursorpos"], capture_output=True, text=True, timeout=3
        ).stdout.strip().split(","))
        clients = json.loads(subprocess.run(
            ["hyprctl", "-j", "clients"], capture_output=True, text=True, timeout=3
        ).stdout.strip())
        for c in clients:
            if c.get("class", "") in ("Eww", "eww"):
                x, y = c["at"]
                w, h = c["size"]
                if x <= cx <= x + w and y <= cy <= y + h:
                    return True
    except Exception:
        pass
    return False

def eww_windows_open():
    result = subprocess.run(
        ["eww", "active-windows"], capture_output=True, text=True, timeout=3
    )
    return bool(result.stdout.strip())

def should_close():
    if not eww_windows_open():
        return False
    focused = get_active_class()
    if focused in PANEL_CLASSES:
        return False
    if cursor_inside_any_eww():
        return False
    return True

def main():
    if not os.path.exists(SOCKET_PATH):
        print("Hyprland socket not found", file=sys.stderr)
        sys.exit(1)

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(SOCKET_PATH)
    sock.sendall(b"activewindow\nopenwindow\nclosewindow\nworkspace\n")
    sock.shutdown(socket.SHUT_WR)

    buf = b""

    while True:
        r, _, _ = select.select([sock], [], [], 1.0)
        if r:
            try:
                chunk = sock.recv(4096)
                if not chunk:
                    break
                buf += chunk
                while b"\n" in buf:
                    line, buf = buf.split(b"\n", 1)
                    event = line.decode().strip()
                    if event.startswith("activewindow>>"):
                        focused = event.split(">>", 1)[1].split(",")[0]
                        if focused not in PANEL_CLASSES:
                            close_all_panels()
                    elif event.startswith("openwindow>>"):
                        parts = event.split(">>", 1)[1].split(",")
                        new_class = parts[2] if len(parts) > 2 else ""
                        if new_class not in PANEL_CLASSES:
                            close_all_panels()
                    elif event.startswith("workspace>>"):
                        close_all_panels()
            except BlockingIOError:
                pass
        else:
            if should_close():
                close_all_panels()

if __name__ == "__main__":
    main()
