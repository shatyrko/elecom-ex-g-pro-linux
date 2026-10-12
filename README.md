# ELECOM EX-G Pro trackball on Linux

Linux settings app and button remapper for the ELECOM EX-G Pro trackball (M-XPT1MR), the Mouse Assistant equivalent: assign any shortcut, action, app or command.

The device: **ELECOM EX-G Pro** thumb trackball, **M-XPT1MR** series (M-XPT1MRBK, M-XPT1MRXBK): USB `056e:0128`, 2.4 GHz receiver `056e:0129`, Bluetooth `056e:0130` (“EX-G Pro TrackBall”).

This repository contains a small **settings app** and a **background service** for it. The app
shows the device's real product photo with every key, button, knob or wheel direction as a
clickable area. Click one (or just press it on the device: it lights up and gets selected) and
choose what it does:

- **its own key** (what the device sends anyway),
- **any keyboard shortcut**: press *Record* and then the shortcut, or type it (`ctrl+shift+z`, `super+e`, `f5`),
- **a desktop action**: volume, brightness, media, next / previous desktop, scroll through windows,
  overview, fullscreen, screenshots, launcher, clipboard, do not disturb, lock, sleep… (see *Desktop actions* below),
- **open an app**, **run a command**, **type text**, or **nothing**.

Knobs and wheels have both directions (and *press* where they press) plus quick presets (volume,
brightness, scroll windows, switch desktops, zoom, page scroll, undo / redo, tracks). Settings are
for **all apps** or **per app** (a profile is used while that app's window is focused). *Try it*
runs an action right away. A shortcut on a mouse button is held while the button is held.

## What the device sends

| Control | Sends on its own | Here |
| --- | --- | --- |
| Left button | Left click (`BTN_LEFT`) | locked (stays left click) |
| Right button | Right click (`BTN_RIGHT`) | assignable |
| Wheel click | Middle click (wheel) (`BTN_MIDDLE`) | assignable |
| Wheel, tilt left | Scroll left (`REL_HWHEEL-`) | assignable |
| Wheel, tilt right | Scroll right (`REL_HWHEEL+`) | assignable |
| Forward (upper thumb key) | Forward (`BTN_EXTRA`) | assignable |
| Back (lower thumb key) | Back (`BTN_SIDE`) | assignable |
| Fn1 (right edge) | Button 11 (`BTN_BACK`) | assignable |
| Fn2 (behind the wheel) | Button 12 (`BTN_TASK`) | assignable |
| Fn3 (under the ball) | Button 10 (`BTN_FORWARD`) | assignable |

- All 8 buttons reach Linux as they are (no kernel fix-up needed): left, right, wheel click, Back / Forward (above the ball), Fn1 (right edge), Fn2 (behind the wheel), Fn3 (under the ball), plus the wheel tilt (horizontal scroll).
- ELECOM Mouse Assistant (Windows / macOS) also remaps on the computer: the trackball stores nothing, so this app is the Linux equivalent, not a workaround.
- Pointer speed (500 / 1000 / 1500) is the button under the trackball; it works inside the device.
- The order of Fn1 / Fn2 / Fn3 comes from another Linux project: run **Which button is which?** once.
- Left click is locked to left click (so the mouse always stays usable).

## How it works

```
device ──evdev──▶ macro-keys service ──uinput──▶ desktop
                  (takes over only this device,      (a virtual keyboard / mouse
                   turns presses into actions)        “EX-G Pro (remapped)”)
macro-keys-studio (the app) ◀── socket ──▶ service: live presses, “Try it”
~/.config/macro-keys/exgpro.json: the settings (the service reloads them at once)
```

- The service reads the device's own input devices (`/dev/input/event*`, found by name in
  `/proc/bus/input/devices`) and **grabs** them (`EVIOCGRAB`): only this device, never your real
  keyboard or other mice. Every press becomes the configured action; keys, buttons and directions
  without a setting are sent on unchanged through its own virtual device (`/dev/uinput`).
  Movement and scrolling of the mouse pass straight through, buttons too (held for dragging).
- No compiled code and no extra Python packages: the service talks to evdev and uinput with plain
  `ioctl` calls. The app is Python + GTK 4 + libadwaita.
- Turn **Use these settings** off in the app and the device sends its own keys again (the service
  lets go of it). Stop the service (`systemctl --user stop exg-pro.service`) and the device is plain.
- The device is described in `devices/exgpro.py` (plain data): its input device names, controls,
  what each sends, the product photo and each control's area on it. Another device can be added
  the same way.

### The product photo

The photo is **not** in this repository (it belongs to its maker). On first start the app downloads
it once from the listing URL in `devices/exgpro.py`, prepares it (crop, scale, background removed)
and keeps it in `~/.cache/macro-keys/photos/`. The launcher icon is made from it too (a small cut-out of the device).
Without internet on first start the app still works (the list of controls); the photo appears
once it can be downloaded.

## Requirements

- Linux with **systemd** (user services) and a **Wayland** or X11 desktop.
- **Python 3.11+** with **PyGObject**, **GTK 4**, **libadwaita** (1.5+) and **pycairo**:
  - Arch: `sudo pacman -S python-gobject gtk4 libadwaita python-cairo`
  - Debian / Ubuntu (24.04+): `sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-4.0 gir1.2-adw-1`
  - Fedora: `sudo dnf install python3-gobject gtk4 libadwaita python3-cairo`
- Access to the input devices: your user in the **`input`** group and `/dev/uinput` writable for
  that group. `install.sh` sets this up (one udev rule, asks for sudo once).
- `gtk-launch` (from GTK 3) for the *Open an app* action.

## Install

```bash
git clone https://github.com/shatyrko/elecom-ex-g-pro-linux.git
cd elecom-ex-g-pro-linux
./install.sh
```

`install.sh` puts everything into your home folder:

| What | Where |
| --- | --- |
| the service and the app | `~/.local/bin/macro-keys`, `~/.local/bin/macro-keys-studio` |
| the device description | `~/.local/share/macro-keys/devices/exgpro.py` |
| the user service | `~/.config/systemd/user/exg-pro.service` (enabled, started at login) |
| the launcher entry and icon | `~/.local/share/applications/dev.alecsh.ExgPro.desktop`, `~/.local/share/icons/hicolor/scalable/apps/dev.alecsh.ExgPro.svg` |
| the access rule (sudo, once) | `/etc/udev/rules.d/60-macro-keys-uinput.rules`, your user added to `input` |

If it added you to the `input` group, **log out and in once**. Then open **EX-G Pro** from your
app launcher (or run `macro-keys-studio --device exgpro`).

The other device apps of this family use the same engine; installing several of them is fine
(each brings its own device file, service and launcher).

## Use

1. Connect the device and open the app. The title says *connected*.
2. Run **Which button is which?** once (bottom of the photo), if offered.
3. Click a control (or press it on the device), choose what it does. Changes apply at once.
4. **+** next to *Profile*: settings for one app (used while it is focused). Anything not set there
   behaves as in *All apps*.

### Desktop actions

The *Desktop action* list calls the commands of the **Noctalia** shell and the **Umbriel** Wayland
compositor (`noctalia msg …`, `umbriel msg …`), which is the desktop this was written on. On other
desktops use **Keyboard shortcut** (your desktop's own shortcuts), **Run a command** (for example
`wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+`, `playerctl play-pause`, `brightnessctl set +5%`),
**Open an app** or **Type text**; they work everywhere. Per-app profiles need to know the focused
window: that comes from `umbriel windows --json`; elsewhere *All apps* is used.

## Uninstall

```bash
./uninstall.sh            # keeps your settings (~/.config/macro-keys/exgpro.json)
./uninstall.sh --purge    # removes them too
```

The engine (`macro-keys`, `macro-keys-studio`) and the udev rule stay while another device app of
this family is installed; the script says what it leaves.

## Troubleshooting

- **The title says “not connected”**: the device's input devices are found by name; check
  `grep -A4 -i 'ELECOM' /proc/bus/input/devices` and compare with `inputs` in
  `devices/exgpro.py`.
- **Nothing happens on a press**: `journalctl --user -u exg-pro.service -f` while pressing; the service
  logs the input devices it took over. Check `ls -l /dev/uinput` (group `input`, `rw`) and `id` (in `input`).
- **A highlight lands next to its button**: the areas on the photo are in `hot` in `devices/exgpro.py`
  (pixels of the prepared photo in `~/.cache/macro-keys/photos/`).
- **Record a shortcut** captures it in the app window; the recorded keys are evdev key names.

## Other devices of this family

- [Ulanzi D100H Dial on Linux](https://github.com/shatyrko/ulanzi-d100h-linux)
- [Hagibis UC-1102A knob dock on Linux](https://github.com/shatyrko/hagibis-uc1102a-linux)
- [ELECOM HUGE trackball on Linux](https://github.com/shatyrko/elecom-huge-linux)
- [Acer OMR225 mouse on Linux](https://github.com/shatyrko/acer-omr225-linux)

## License

MIT, see [LICENSE](LICENSE). Product names and photos belong to their owners; the photos are not
part of this repository. Not affiliated with the device makers.
