#!/usr/bin/env python3
"""Vista general de ventanas al estilo Windows Task View para Hyprland."""

import json
import os
import subprocess
import sys

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib, Pango


def hyprctl(cmd):
    return subprocess.run(
        ['hyprctl'] + cmd.split(),
        capture_output=True, text=True
    ).stdout


def hyprctl_json(cmd):
    return json.loads(hyprctl(cmd + ' -j'))


class WindowOverview(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_title("Vista general")
        self.set_default_size(0, 0)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_accept_focus(True)
        self.set_can_focus(True)
        self.fullscreen()

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        css = b"""
        .overview-bg {
            background-color: rgba(0, 0, 0, 0.75);
        }
        #overview-title {
            font-size: 20px;
            font-weight: bold;
            color: #cdd6f4;
        }
        .workspace-box {
            background-color: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 16px;
            padding: 12px;
        }
        .workspace-label {
            font-size: 11px;
            font-weight: bold;
            color: #cba6f7;
            margin-bottom: 6px;
        }
        .window-card {
            background-color: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.10);
            border-radius: 12px;
            padding: 10px 14px;
        }
        .window-card:hover {
            background-color: rgba(203, 166, 247, 0.15);
            border-color: rgba(203, 166, 247, 0.30);
        }
        .window-title {
            font-size: 12px;
            color: #cdd6f4;
        }
        .window-class {
            font-size: 10px;
            color: #a6adc8;
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
        self.connect('button-press-event', self.on_click_outside)

        self.build_ui()

    def build_ui(self):
        overlay = Gtk.Overlay()
        self.add(overlay)
        overlay.get_style_context().add_class('overview-bg')

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        main_box.set_valign(Gtk.Align.CENTER)
        main_box.set_halign(Gtk.Align.CENTER)
        main_box.set_margin_top(60)
        main_box.set_margin_bottom(60)
        main_box.set_margin_start(60)
        main_box.set_margin_end(60)

        title = Gtk.Label(label="Vista general de ventanas")
        title.set_name("overview-title")
        main_box.pack_start(title, False, False, 0)

        self.windows = hyprctl_json('clients')
        workspaces = {}
        for w in self.windows:
            ws_id = w.get('workspace', {}).get('id', 0)
            if ws_id <= 0:
                continue
            if w.get('mapped') != True:
                continue
            ws_id = w['workspace']['id']
            if ws_id not in workspaces:
                workspaces[ws_id] = []
            workspaces[ws_id].append(w)

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_min_content_height(400)

        ws_grid = Gtk.FlowBox(
            orientation=Gtk.Orientation.HORIZONTAL,
            valign=Gtk.Align.START,
            halign=Gtk.Align.CENTER,
            max_children_per_line=4,
            min_children_per_line=1,
            column_spacing=20,
            row_spacing=20,
            homogeneous=True,
        )

        for ws_id in sorted(workspaces.keys()):
            ws_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
            ws_box.get_style_context().add_class('workspace-box')

            ws_label = Gtk.Label(label=f"Workspace {ws_id}", xalign=0)
            ws_label.get_style_context().add_class('workspace-label')
            ws_box.pack_start(ws_label, False, False, 0)

            for win in workspaces[ws_id]:
                title = win.get('title', '') or win.get('class', '')
                cls = win.get('class', '')
                addr = win.get('address', '')
                win_box = Gtk.EventBox()
                win_box.get_style_context().add_class('window-card')
                win_box.connect('button-press-event', self.on_window_click, addr)

                vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
                t_label = Gtk.Label(
                    label=title if len(title) < 60 else title[:57] + '...',
                    xalign=0, wrap=True, max_width_chars=30
                )
                t_label.get_style_context().add_class('window-title')
                c_label = Gtk.Label(label=cls, xalign=0)
                c_label.get_style_context().add_class('window-class')

                vbox.pack_start(t_label, False, False, 0)
                vbox.pack_start(c_label, False, False, 0)
                win_box.add(vbox)
                ws_box.pack_start(win_box, False, False, 0)

            ws_grid.add(ws_box)

        scroll.add(ws_grid)
        main_box.pack_start(scroll, True, True, 0)

        hint = Gtk.Label(
            label="Click en una ventana para enfocarla  ·  Escape para cerrar  ·  q para cerrar"
        )
        hint.get_style_context().add_class('hint-label')
        hint.set_margin_top(12)
        main_box.pack_start(hint, False, False, 0)

        overlay.add(main_box)

        GLib.idle_add(self.focus_window)

    def focus_window(self):
        self.present()
        self.grab_focus()
        return False

    def on_window_click(self, widget, event, address):
        hyprctl(f'dispatch focuswindow address:{address}')
        Gtk.main_quit()

    def on_click_outside(self, widget, event):
        Gtk.main_quit()

    def on_key_press(self, widget, event):
        if event.keyval in (Gdk.KEY_Escape, Gdk.KEY_q):
            Gtk.main_quit()


if __name__ == '__main__':
    win = WindowOverview()
    win.show_all()
    Gtk.main()
