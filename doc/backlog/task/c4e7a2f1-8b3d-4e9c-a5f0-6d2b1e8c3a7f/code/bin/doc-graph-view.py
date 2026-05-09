# [[ref:b9e3f1c5-2d8a-4b7f-a5d3-7c0e4f2b9d1e][Specification]]

import os
import subprocess
import sys

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

import xdot.ui as xdot_ui


class DocGraphWindow(xdot_ui.DotWindow):
    """DotWindow that opens org-mode nodes in Emacs on click."""

    def __init__(self):
        super().__init__()
        self.dotwidget.connect('clicked', self._on_clicked)

    def _on_clicked(self, _widget, url, _event):
        if url.startswith('org-id://'):
            uuid = url[len('org-id://'):]
            socket = os.environ.get('EMACSD_SOCKET', '')
            cmd = ['emacsclient', '--no-wait']
            if socket:
                cmd.append(f'--socket-name={socket}')
            cmd += ['--eval', f'(org-id-open "{uuid}" t)']
            subprocess.Popen(cmd)


def main():
    dotfile = sys.argv[1] if len(sys.argv) > 1 else None
    win = DocGraphWindow()
    if dotfile:
        win.open_file(dotfile)
    else:
        win.set_dotcode(sys.stdin.buffer.read())
    win.connect('delete-event', lambda *_: Gtk.main_quit())
    Gtk.main()


if __name__ == '__main__':
    main()
