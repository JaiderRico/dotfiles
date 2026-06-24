#!/usr/bin/env python3
"""Vista general de ventanas al estilo Windows Task View para Hyprland."""

import json
import os
import signal
import subprocess
import sys
import tempfile
import time

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GdkPixbuf', '2.0')
from gi.repository import Gtk, Gdk, GLib, GdkPixbuf


LOCK_FILE = '/tmp/hypr-overview.lock'
TMP_DIR = os.path.join(tempfile.gettempdir(), 'hypr-overview')
SCREENSHOTS_READY = os.path.join(TMP_DIR, '.ready')


def _clean_lock():
    if os.path.exists(LOCK_FILE):
        try:
            with open(LOCK_FILE) as f:
                my_pid = int(f.read().strip())
            if my_pid == os.getpid():
                os.unlink(LOCK_FILE)
        except (OSError, ValueError):
            pass

signal.signal(signal.SIGTERM, lambda *_: (_clean_lock(), sys.exit(0)))
signal.signal(signal.SIGINT, lambda *_: (_clean_lock(), sys.exit(0)))

try:
    if os.path.exists(LOCK_FILE):
        with open(LOCK_FILE) as f:
            old_pid = int(f.read().strip())
        try:
            os.kill(old_pid, 0)
            sys.exit(0)
        except ProcessLookupError:
            pass
        try:
            os.unlink(LOCK_FILE)
        except OSError:
            pass
    lock_fd = os.open(LOCK_FILE, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
    os.write(lock_fd, str(os.getpid()).encode())
    os.close(lock_fd)
except FileExistsError:
    sys.exit(0)
except (OSError, ValueError):
    sys.exit(0)


def hyprctl(cmd):
    return subprocess.run(
        ['hyprctl'] + cmd.split(),
        capture_output=True, text=True
    ).stdout


def hyprctl_json(cmd):
    return json.loads(hyprctl(cmd + ' -j'))

# ─── Captura previa (antes de abrir la ventana) ──────────────


def pre_capture_all():
    """Captura screenshots de todos los workspaces ANTES de mostrar la UI."""
    os.makedirs(TMP_DIR, exist_ok=True)

    active_ws = hyprctl_json('activeworkspace')['id']
    windows = hyprctl_json('clients')

    workspaces = {}
    for w in windows:
        ws_id = w.get('workspace', {}).get('id', 0)
        if ws_id <= 0 or w.get('mapped') != True:
            continue
        ws_id = w['workspace']['id']
        if ws_id not in workspaces:
            workspaces[ws_id] = []
        workspaces[ws_id].append(w)

    for ws_id in sorted(workspaces.keys()):
        wins = workspaces[ws_id]
        if ws_id == active_ws:
            for win in wins:
                addr = win.get('address', '')
                x, y = win.get('at', [0, 0])
                w, h = win.get('size', [100, 100])
                out = os.path.join(TMP_DIR, f'{addr}.png')
                subprocess.run(
                    ['grim', '-g', f'{x},{y} {w}x{h}', out],
                    capture_output=True, text=True
                )
        else:
            hyprctl(f'dispatch workspace {ws_id}')
            full = os.path.join(TMP_DIR, f'ws_{ws_id}_full.png')
            subprocess.run(['grim', full], capture_output=True, text=True)
            if os.path.exists(full):
                try:
                    full_pb = GdkPixbuf.Pixbuf.new_from_file(full)
                    for win in wins:
                        addr = win.get('address', '')
                        x, y = win.get('at', [0, 0])
                        w, h = win.get('size', [100, 100])
                        if w <= 0 or h <= 0:
                            continue
                        crop = GdkPixbuf.Pixbuf.new(
                            GdkPixbuf.Colorspace.RGB, True, 8, w, h
                        )
                        full_pb.copy_area(x, y, w, h, crop, 0, 0)
                        out2 = os.path.join(TMP_DIR, f'{addr}.png')
                        crop.savev(out2, 'png', [], [])
                    os.unlink(full)
                except Exception:
                    pass

    hyprctl(f'dispatch workspace {active_ws}')
    open(SCREENSHOTS_READY, 'w').close()
    return workspaces, active_ws


# ─── Iconos ───────────────────────────────────────────────────

ICON_MAP = {
    'firefox': 'firefox',
    'kitty': 'terminal',
    'code-oss': 'visual-studio-code',
    'code': 'visual-studio-code',
    'onlyoffice': 'office-document',
    'zapzap': 'telegram',
    'nautilus': 'folder',
    'thunar': 'folder',
    'vlc': 'vlc',
    'rofi': 'system-run',
    'eww': 'system-run',
    'waybar': 'system-run',
    'dunst': 'dialog-information',
    'swaync': 'dialog-information',
    'blueman-manager': 'bluetooth',
    'pavucontrol': 'multimedia-volume-control',
}


def get_app_icon(cls):
    theme = Gtk.IconTheme.get_default()
    name = ICON_MAP.get(cls.lower(), 'application-x-executable')
    for attempt in (name, 'application-x-executable'):
        icon = theme.lookup_icon(attempt, 64, 0)
        if icon:
            try:
                return icon.load_icon()
            except Exception:
                pass
    return None


# ─── GTK Window ───────────────────────────────────────────────

class WindowOverview(Gtk.Window):
    def __init__(self, workspaces, active_ws):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_title("Vista general")
        self.set_default_size(0, 0)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_accept_focus(True)
        self.set_can_focus(True)
        self.fullscreen()

        self.active_ws = active_ws

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        css = b"""
        .overview-bg {
            background-color: rgba(0, 0, 0, 0.72);
        }
        #overview-title {
            font-size: 18px;
            font-weight: bold;
            color: #cdd6f4;
        }
        .ws-column {
            background-color: rgba(255, 255, 255, 0.04);
            border: 1px solid rgba(255, 255, 255, 0.06);
            border-radius: 18px;
            padding: 14px;
        }
        .ws-column.active {
            border-color: rgba(203, 166, 247, 0.25);
            background-color: rgba(203, 166, 247, 0.04);
        }
        .ws-label {
            font-size: 11px;
            font-weight: bold;
            color: #585b70;
        }
        .ws-label.active {
            color: #cba6f7;
        }
        .window-card {
            background-color: rgba(255, 255, 255, 0.05);
            border: 2px solid rgba(255, 255, 255, 0.06);
            border-radius: 14px;
            padding: 5px;
        }
        .window-card:hover {
            background-color: rgba(203, 166, 247, 0.10);
            border-color: rgba(203, 166, 247, 0.30);
        }
        .win-title {
            font-size: 11px;
            color: #cdd6f4;
            padding: 2px 4px 0;
        }
        .hint-label {
            font-size: 11px;
            color: #585b70;
        }
        """

        style_provider = Gtk.CssProvider()
        style_provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(
            screen, style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.connect('key-press-event', self.on_key_press)
        self.connect('destroy', lambda _: self.cleanup())

        self.build_ui(workspaces)
        self.load_images()

    def build_ui(self, workspaces):
        overlay = Gtk.Overlay()
        self.add(overlay)
        overlay.get_style_context().add_class('overview-bg')

        main_box = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL, spacing=16
        )
        main_box.set_valign(Gtk.Align.CENTER)
        main_box.set_halign(Gtk.Align.CENTER)
        main_box.set_margin_top(50)
        main_box.set_margin_bottom(50)
        main_box.set_margin_start(40)
        main_box.set_margin_end(40)

        title = Gtk.Label(label="Vista general")
        title.set_name("overview-title")
        main_box.pack_start(title, False, False, 0)

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_min_content_height(350)

        hbox = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL,
            spacing=20, halign=Gtk.Align.CENTER,
            valign=Gtk.Align.START
        )

        self.cards = {}
        for ws_id in sorted(workspaces.keys()):
            is_active = ws_id == self.active_ws
            ws_box = Gtk.Box(
                orientation=Gtk.Orientation.VERTICAL, spacing=8
            )
            ws_box.get_style_context().add_class('ws-column')
            if is_active:
                ws_box.get_style_context().add_class('active')

            badge = "● " if is_active else "  "
            ws_label = Gtk.Label(label=f"{badge}Workspace {ws_id}", xalign=0)
            ws_label.get_style_context().add_class('ws-label')
            if is_active:
                ws_label.get_style_context().add_class('active')
            ws_box.pack_start(ws_label, False, False, 0)

            for win in workspaces[ws_id]:
                title = win.get('title', '') or win.get('class', '')
                cls = win.get('class', '')
                addr = win.get('address', '')

                box = Gtk.EventBox()
                box.get_style_context().add_class('window-card')
                box.connect(
                    'button-press-event', self.on_window_click, addr
                )

                vbox = Gtk.Box(
                    orientation=Gtk.Orientation.VERTICAL, spacing=3
                )

                img = Gtk.Image()
                img.set_size_request(200, -1)
                vbox.pack_start(img, False, False, 0)

                t_label = Gtk.Label(
                    label=title if len(title) < 45
                    else title[:42] + '...',
                    xalign=0, wrap=True, max_width_chars=28
                )
                t_label.get_style_context().add_class('win-title')
                vbox.pack_start(t_label, False, False, 0)

                box.add(vbox)
                ws_box.pack_start(box, False, False, 0)

                self.cards[addr] = {
                    'img': img, 'class': cls,
                    'ws_id': ws_id, 'is_active_ws': is_active,
                }

            hbox.pack_start(ws_box, False, False, 0)

        scroll.add(hbox)
        main_box.pack_start(scroll, True, True, 0)

        hint = Gtk.Label(
            label="Click en una ventana · Escape/q para cerrar"
        )
        hint.get_style_context().add_class('hint-label')
        hint.set_margin_top(8)
        main_box.pack_start(hint, False, False, 0)

        overlay.add(main_box)
        self.show_all()
        self.present()
        self.grab_focus()

    def load_images(self):
        for addr, info in self.cards.items():
            path = os.path.join(TMP_DIR, f'{addr}.png')
            if os.path.exists(path) and os.path.getsize(path) > 0:
                try:
                    pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                        path, 200, 130, True
                    )
                    if pb:
                        info['img'].set_from_pixbuf(pb)
                        continue
                except Exception:
                    pass
            pb = self._make_placeholder(info['class'])
            if pb:
                info['img'].set_from_pixbuf(pb)

    def _make_placeholder(self, cls, w=200, h=130):
        pb = GdkPixbuf.Pixbuf.new(
            GdkPixbuf.Colorspace.RGB, True, 8, w, h
        )
        pb.fill(0x1e1e2ecc)
        icon_pb = get_app_icon(cls)
        if icon_pb:
            sw = min(icon_pb.get_width(), 48)
            sh = min(icon_pb.get_height(), 48)
            try:
                scaled = icon_pb.scale_simple(
                    sw, sh, GdkPixbuf.InterpType.BILINEAR
                )
                scaled.copy_area(
                    0, 0, sw, sh, pb, (w - sw) // 2, (h - sh) // 2 - 6
                )
            except Exception:
                pass
        return pb

    def on_window_click(self, widget, event, address):
        hyprctl(f'dispatch focuswindow address:{address}')
        Gtk.main_quit()

    def on_key_press(self, widget, event):
        if event.keyval in (Gdk.KEY_Escape, Gdk.KEY_q, Gdk.KEY_Q):
            Gtk.main_quit()

    def cleanup(self):
        _clean_lock()
        if os.path.isdir(TMP_DIR):
            for f in os.listdir(TMP_DIR):
                try:
                    os.remove(os.path.join(TMP_DIR, f))
                except OSError:
                    pass
            try:
                os.rmdir(TMP_DIR)
            except OSError:
                pass


# ─── Entry point ──────────────────────────────────────────────

if __name__ == '__main__':
    workspaces, active_ws = pre_capture_all()
    win = WindowOverview(workspaces, active_ws)
    Gtk.main()
