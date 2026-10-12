#!/usr/bin/env bash
# Remove the EX-G Pro app and service.  ./uninstall.sh [--purge]   (--purge: also its settings)
set -euo pipefail
DEV=exgpro APP=dev.alecsh.ExgPro UNIT=exg-pro.service
systemctl --user disable --now "$UNIT" 2>/dev/null || true
rm -f ~/.config/systemd/user/"$UNIT" ~/.local/share/applications/"$APP.desktop" \
      ~/.local/share/icons/hicolor/scalable/apps/"$APP.svg" ~/.local/share/icons/hicolor/256x256/apps/"$APP.png" \
      ~/.local/share/macro-keys/devices/"$DEV.py" ~/.cache/macro-keys/photos/"$DEV".png ~/.cache/macro-keys/photos/"$DEV"-*.png
systemctl --user daemon-reload
[[ ${1:-} == --purge ]] && rm -f ~/.config/macro-keys/"$DEV.json" && echo "settings removed"
if ls ~/.local/share/macro-keys/devices/*.py >/dev/null 2>&1; then
    echo "kept the engine (~/.local/bin/macro-keys*) and the udev rule: other device apps use them"
else
    rm -f ~/.local/bin/macro-keys ~/.local/bin/macro-keys-studio
    echo "engine removed; the udev rule /etc/udev/rules.d/60-macro-keys-uinput.rules stays"
    echo "(remove it with: sudo rm /etc/udev/rules.d/60-macro-keys-uinput.rules)"
fi
update-desktop-database ~/.local/share/applications 2>/dev/null || true
echo "EX-G Pro removed"
