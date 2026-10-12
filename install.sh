#!/usr/bin/env bash
# Install the EX-G Pro app and service for the current user. Run in the repository: ./install.sh
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
DEV=exgpro APP=dev.alecsh.ExgPro UNIT=exg-pro.service
[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root (it asks for sudo when needed)."; exit 1; }

if ! python3 - <<'EOF' 2>/dev/null
import sys, gi, cairo
gi.require_version("Gtk", "4.0"); gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw
assert sys.version_info >= (3, 11)
EOF
then
    echo "Missing: Python 3.11+ with PyGObject, GTK 4, libadwaita and pycairo."
    echo "  Arch:          sudo pacman -S python-gobject gtk4 libadwaita python-cairo"
    echo "  Debian/Ubuntu: sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-4.0 gir1.2-adw-1"
    echo "  Fedora:        sudo dnf install python3-gobject gtk4 libadwaita python3-cairo"
    exit 1
fi

install -Dm755 bin/macro-keys ~/.local/bin/macro-keys
install -Dm755 bin/macro-keys-studio ~/.local/bin/macro-keys-studio
install -Dm644 "devices/$DEV.py" ~/.local/share/macro-keys/devices/"$DEV.py"
install -Dm644 "systemd/$UNIT" ~/.config/systemd/user/"$UNIT"
install -Dm644 "desktop/$APP.desktop" ~/.local/share/applications/"$APP.desktop"
install -Dm644 "icons/$APP.svg" ~/.local/share/icons/hicolor/scalable/apps/"$APP.svg"
echo "installed into your home folder"

# access to the devices: /dev/uinput for the input group, you in the input group (sudo, once)
relogin=0
if [[ ! -f /etc/udev/rules.d/60-macro-keys-uinput.rules ]] && ! [[ -w /dev/uinput && -r /dev/input/event0 ]]; then
    echo "Setting up device access (asks for your password once):"
    sudo install -Dm644 udev/60-macro-keys-uinput.rules /etc/udev/rules.d/60-macro-keys-uinput.rules
    sudo modprobe uinput || true
    sudo udevadm control --reload
    sudo udevadm trigger --name-match=uinput || true
fi
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx input; then
    sudo gpasswd -a "$USER" input
    relogin=1
fi

systemctl --user daemon-reload
systemctl --user enable "$UNIT" >/dev/null
if ((relogin)); then
    echo
    echo "You were added to the input group: log out and in once, then the service starts by itself."
else
    systemctl --user restart "$UNIT"
    echo "service $UNIT running"
fi
update-desktop-database ~/.local/share/applications 2>/dev/null || true
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null || true
echo "Done: open “EX-G Pro” from your app launcher (or: macro-keys-studio --device $DEV)."
