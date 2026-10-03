# dwm

A complete, ready-to-run desktop for Arch-based Linux, built around a patched
[dwm](https://dwm.suckless.org) window manager and a
[Quickshell](https://quickshell.org) status bar.

Instead of dragging windows around, dwm arranges them for you: open a second
window and the screen splits, close it and the remaining windows fill the space.
Everything is driven from the keyboard, with the mouse available when you want
it. The bar across the top shows your workspaces, the focused window, the clock,
and small indicators for volume, network, battery, Bluetooth and pending updates.

The whole desktop is black, with one accent colour used only to show what has
your attention.

**New to tiling window managers?** Start with [Quick start](#quick-start), then
[Daily use](#daily-use). You do not need to read any code.

**Here to work on it?** Jump to [Development](#development).

---

## Contents

- [What you get](#what-you-get)
- [Quick start](#quick-start)
- [Daily use](#daily-use)
  - [Keyboard shortcuts](#keyboard-shortcuts)
  - [The bar](#the-bar)
- [Configuration](#configuration)
  - [HiDPI and 4K screens](#hidpi-and-4k-screens)
  - [Small screens](#small-screens)
  - [Changing shortcuts, colours and autostart](#changing-shortcuts-colours-and-autostart)
- [Requirements](#requirements)
- [Development](#development)
- [Project layout](#project-layout)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## What you get

| | |
|---|---|
| **Window manager** | dwm 0.3, patched (see [Project layout](#project-layout)) |
| **Status bar** | Quickshell, 22 QML files in `config/quickshell` |
| **Terminal** | ghostty |
| **Menus and launcher** | rofi — application launcher, power menu, repository finder, bookmarks |
| **Notifications** | dunst |
| **Compositor** | picom |
| **Screenshots** | flameshot |
| **Theme** | Black with Nord accents, applied to dwm, the bar, rofi, GTK and Qt |

Nine workspaces, three layouts (tiled, floating, monocle), and multi-monitor
support with the workspaces split across whatever screens you have.

## Quick start

On an Arch-based system, as your normal user:

```bash
git clone https://github.com/gameshler/dwm.git
cd dwm
./install.sh
```

The installer asks for your password when it needs root. It will:

1. Install the packages the desktop needs.
2. Build and install dwm.
3. Copy `config/*` into `~/.config` and `scripts/*` into `~/.local/bin`.
4. Put the wallpapers in `~/Pictures/backgrounds`.
5. Register dwm as a session you can pick at the login screen.

Then log out and log back in, choosing **dwm** at your login screen. Without a
login manager, log in on a TTY and run `startx`.

Press **Super + r** to open the application launcher and **Super + x** for a
terminal.

Re-run `./install.sh` any time to pick up changes. It refreshes the files this
repo ships and leaves anything else in those directories alone.

> **Already using [archsetup](https://github.com/gameshler/archsetup)?** Its dwm
> tab does the same job. Use one or the other, not both.

### Installing only part of it

The package lists at the top of `install.sh` are split into three groups:
`REQUIRED_PACKAGES`, `BAR_PACKAGES` and `DESKTOP_PACKAGES`. Edit the last two to
drop anything you do not want. See [Requirements](#requirements) for what each
group actually provides.

## Daily use

**Super** is the modifier key — the Windows key on most keyboards.

### Keyboard shortcuts

Launching things:

| Shortcut | Action |
|---|---|
| `Super + r` | Application launcher |
| `Super + x` | Terminal |
| `Super + e` | File manager |
| `Super + b` | Browser |
| `Super + a` | ChatGPT |
| `Super + Shift + w` | Random wallpaper |

Windows:

| Shortcut | Action |
|---|---|
| `Super + j` / `Super + k` | Focus the next / previous window |
| `Super + Shift + j` / `Super + Shift + k` | Move the focused window in the stack |
| `Super + Return` | Promote the focused window to the master area |
| `Super + q` | Close the focused window |
| `Super + Tab` | Back to the previous workspace |
| `Super + m` | Fullscreen |
| `Super + space` | Toggle floating |

Resizing:

| Shortcut | Action |
|---|---|
| `Super + h` / `Super + l` | Shrink / grow the master area |
| `Super + Shift + h` / `Super + Shift + l` | Grow / shrink the focused window |
| `Super + Shift + o` | Reset the focused window's size |
| `Super + i` / `Super + d` | More / fewer windows in the master area |

Layouts:

| Shortcut | Action |
|---|---|
| `Super + t` | Tiled — windows share the screen |
| `Super + f` | Floating — windows keep their own size and position |
| `Super + Shift + m` | Monocle — one window at a time, full area |
| `Super + Shift + y` | Toggle fake fullscreen (fullscreen inside the window's own frame) |
| `Super + Shift + b` | Show or hide the bar |

Workspaces, where `N` is `1`–`9`:

| Shortcut | Action |
|---|---|
| `Super + N` | Go to workspace N |
| `Super + Shift + N` | Move the focused window to workspace N |
| `Super + Ctrl + N` | Show workspace N alongside the current one |
| `Super + 0` | Show every workspace at once |

Multiple monitors:

| Shortcut | Action |
|---|---|
| `Super + ,` / `Super + .` | Focus the previous / next monitor |
| `Super + Shift + ,` / `Super + Shift + .` | Send the focused window to that monitor |

Screenshots:

| Shortcut | Action |
|---|---|
| `Super + p` | Whole screen, saved to disk |
| `Super + Shift + p` | Select a region, saved to disk |
| `Super + Ctrl + p` | Select a region, copied to the clipboard |

> The two that save to disk write to `/media/drive/Screenshots/`, which is
> specific to the author's machine. If that path does not exist on yours,
> change it in the two `flameshot` lines in `config.h` and rebuild, or create
> the directory.

Session:

| Shortcut | Action |
|---|---|
| `Super + Ctrl + q` | Power menu |
| `Super + Ctrl + Shift + r` | Reboot |
| `Super + Ctrl + Shift + s` | Suspend |
| `Super + Shift + q` | Quit dwm |

Extras:

| Shortcut | Action |
|---|---|
| `Super + Ctrl + Shift + t` | Repository finder |
| `Super + Ctrl + Shift + b` | Bookmarks menu |
| `Super + Ctrl + r` | Force-quit every Wine, Proton and game-launcher process |

Mouse, on a window: `Super` + left-drag moves it, `Super` + right-drag resizes
it. On the bar's workspace numbers: left-click to switch, right-click to show a
workspace alongside the current one.

### The bar

Left to right:

- **Workspace numbers.** A wide accent underline marks the one you are viewing;
  a small grey dot marks one holding windows. Click to switch.
- **The focused window's title**, dimmed, so it reads as context rather than
  competing with the clock.
- **The clock**, centred on the screen.
- **Status text**, if you run a status program such as `slstatus` or `dwmblocks`
  that writes with `xsetroot -name`. Shown only when there is room.
- **Pending updates.** Hidden when there is nothing to install. Click to open
  the updater.
- **Running applications.** One greyscale icon per application; hovering
  restores its real colours. The focused one gets an accent underline. Click to
  focus. Capped at a fifth of the bar, with `+3` for what did not fit.
- **System tray**, for applications that provide one. Left-click activates the
  item, right-click opens its menu, middle-click triggers its secondary action.
- **Indicators**, each hidden when its hardware or tool is absent: battery with
  a percentage (green while charging, red at 15% or below, laptops only),
  Bluetooth, network (click to open the connection editor) and volume (click to
  open the mixer, middle-click to mute, scroll to change).
- **Power button.** Opens the power menu.

Hovering any indicator shows a tooltip with the detail.

## Configuration

### HiDPI and 4K screens

The whole desktop scales from one setting. Put it in `~/.Xresources`:

```
Xft.dpi: 192
```

`192` is 2x and `144` is 1.5x. Log out and back in.

That one value sizes dwm's font, rofi and the bar together.
`scripts/.xprofile` loads the file — both the `startx` path and a login manager
source it — and `scripts/quickshell-launch.sh` passes the value on to Qt as
`QT_FONT_DPI`, because Qt is the one toolkit here that does not read `Xft.dpi`
itself: on Xorg it reports a flat 96 DPI whatever the display actually is.
Without that translation the bar would stay at 1x on a 4K panel while everything
around it scaled.

Fractional values work. Qt passes them straight through, so `Xft.dpi: 144`
really is a ratio of 1.5, and the bar switches to a resolution-independent text
renderer whenever the ratio is not a whole number.

Two things worth knowing:

- Setting `QT_FONT_DPI` or `QT_SCALE_FACTOR` yourself in `.xprofile` overrides
  the translation.
- Xorg has a single DPI for the whole display, so a mixed-DPI multi-monitor setup
  scales every monitor by the same factor. That is an X11 limitation, not a
  property of this bar.

`Theme.scale` in `config/quickshell/core/Theme.qml` is a separate manual
multiplier, for making the bar deliberately larger than the rest of the desktop.
Leave it at `1.0` unless that is what you want.

The bar is 40 logical pixels tall at `1.0`, and every icon size is both even and
a size the icon theme actually draws, so icons land on whole pixels instead of
being resampled. A fractional `Theme.scale` gives that up — `1.25` turns a 22px
icon into 27.5 — so prefer `Xft.dpi` above, which scales the whole desktop
together, and reach for `Theme.scale` only to size the bar against everything
else.

### Monitor arrangement

`scripts/display-setup.sh` runs at login, enables every connected output at its
native mode and highest refresh rate, and lays them out left to right. It cannot
know where your monitors physically sit, so by default it orders them the way
`xrandr` lists them, which is by connector name. If that puts a monitor on the
wrong side, say where they actually are in `~/.config/dwm/monitors.conf` — one
output per line, left to right, the first line primary:

```
# my desk, left to right
HDMI-1
DP-2
```

Get the names from:

```bash
xrandr --query | grep " connected"
```

Blank lines and `#` comments are ignored. Outputs that are not connected are
skipped, and any connected output the file does not mention is added on the
right, so plugging in a new monitor still lights it up. With no file the
connector-name order is used.

### Small screens

The bar holds its layout from a 1024-wide netbook to a 32:9 ultrawide. When
space runs short it gives things up in a fixed order:

1. The window title elides.
2. The application dock stops at a fifth of the bar and counts the rest.
3. The status line is dropped — based on whether the room left over actually
   holds it, not on a screen width fixed in advance.

The workspace numbers, the clock, the tray and the power button are never
dropped.

### Changing shortcuts, colours and autostart

| What | Where |
|---|---|
| Shortcuts, window rules, autostart | `config.h`, then rebuild |
| Every bar colour and dimension | `config/quickshell/core/Theme.qml` |
| dwm's own window border colours | `config.h` (kept in sync with `Theme.qml`) |
| rofi menus and theme | `config/rofi/` |
| GTK dark theme | `config/gtk-3.0/`, `config/gtk-4.0/` |
| Session environment | `scripts/.xprofile` |

`config.h` is compiled in, so after editing it:

```bash
make && sudo make install
```

Editing anything under `config/quickshell` takes effect on the next login, or
immediately if you restart the bar.

## Requirements

An Arch-based x86_64 system running **Xorg**. Wayland is not supported.

`install.sh` installs all of this for you. The lists below are the three groups
at the top of that script, for anyone installing by hand or trimming the
install.

### Required

Without these, a keybinding, an autostart entry or the bar points at a missing
binary.

| Packages | Why |
|---|---|
| `base-devel`, `git` | Building |
| `libx11`, `libxinerama`, `libxft`, `libxcb`, `imlib2` | What dwm links against |
| `xorg-server`, `xorg-xinit` | The X session |
| `xorg-xrdb` | Reads `Xft.dpi`, which is what scales the desktop |
| `xorg-xprop` | How the bar reads dwm's state |
| `xorg-xrandr` | Used by `scripts/display-setup.sh` on login |
| `xorg-xset` | Used by `scripts/disable-powersaving` |
| `xorg-xsetroot` | Not called by anything here; present so you can write a status line yourself with `xsetroot -name` |
| `quickshell` | The bar |
| `wmctrl` | Clicking a workspace or an application in the bar |
| `xdotool` | Tracking the focused window |
| `ghostty`, `rofi` | Terminal and menus |
| `picom`, `dunst`, `feh`, `flameshot` | Compositor, notifications, wallpaper, screenshots |
| `dex`, `mate-polkit` | Autostart entries and the polkit agent |
| `xdg-utils`, `xdg-user-dirs`, `xdg-desktop-portal-gtk` | `xdg-open`, user directories, the portal Qt and libadwaita read |
| `ttf-firacode-nerd` | The bar's icons, clock and every number on it |
| `inter-font` | Window titles and tooltips |
| `noto-fonts-emoji` | The emoji fallback in dwm's own `fonts[]` |

Without Inter the bar falls back to Noto Sans, then DejaVu Sans, then the mono
font — see `uiFontFamily` in `core/Theme.qml`.

### Optional

Each bar indicator hides itself when its tool is missing, so everything here can
be dropped. `install.sh` checks `/sys/class/bluetooth` and skips `bluez`
entirely on a machine with no adapter, which is the common case on a wired
desktop. Everything else is installed unconditionally: NetworkManager drives the
network indicator over Ethernet as well as Wi-Fi.

| Packages | Gives you |
|---|---|
| `networkmanager`, `network-manager-applet` | Network indicator and connection editor |
| `bluez`, `bluez-utils` | Bluetooth indicator, installed only when the machine has an adapter |
| `pipewire`, `pipewire-pulse`, `pavucontrol` | Volume indicator and mixer |
| `pacman-contrib` | Accurate update count via `checkupdates` |
| `papirus-icon-theme` | Tray and application icons |

> Use `Papirus`, not `Papirus-Dark`. The Dark variant ships no application
> icons and inherits `breeze-dark`, which empties the bar's application dock
> and tray.

### The surrounding desktop

Not needed by dwm or the bar. This is the rest of the desktop the config is
built around; drop anything you do not want.

`thunar`, `thunar-archive-plugin`, `tumbler`, `gvfs`, `xarchiver`, `xclip`,
`unzip`, `nwg-look`, `alsa-utils`, `gnome-keyring`, `flatpak`, `xscreensaver`,
`tldr`, `tmux`.

## Development

```bash
make                   # build dwm
make CC="cc -Werror"   # the build gate CI runs
make lint              # shellcheck -x, shfmt -d, then qmllint
make check             # the tests/ suite
make clean
sudo make install      # install the binary, session entry, config and scripts
```

Each test also runs on its own: `make check-design-system`, `check-tray`,
`check-layout`, `check-state-protocol`, `check-launcher`, `check-state`,
`check-bar-xvfb`.

`make lint` needs `shellcheck`, `shfmt` and `qt6-declarative`. Any warning fails
the run. qmllint cannot see the `qs.*` modules on its own, because Quickshell
generates them at runtime under `$XDG_RUNTIME_DIR`; `tools/qml-lint.sh` rebuilds
that module tree in a temporary directory first, so it works with no running
shell and no X server.

`make check` runs one script per contract. Most read source and assert something
`SPEC.md` already states, so they need nothing installed. Two run
`quickshell-launch.sh` and `dwm-quickshell-state` for real against stubs on
`PATH`. The last starts dwm and the bar under Xvfb and measures the bar window
at four screen widths and three device pixel ratios; it needs `quickshell`,
`Xvfb`, `xwininfo`, `xterm`, `xdotool` and ImageMagick, and skips itself rather
than failing when they are missing.

CI runs the build, the shell linters, qmllint and the test suite on every push
and every pull request.

For editor support, create an empty `.qmlls.ini` next to
`config/quickshell/shell.qml` and Quickshell will fill it in. It is gitignored,
since it holds machine-local paths.

Contributor documentation lives in `AGENTS.md` (conventions and the validation
gate), `SPEC.md` (requirements and acceptance criteria), `ROADMAP.md` (phase
order) and `TASKS.md` (current work).

## Project layout

```
dwm.c, drw.c, util.c     the window manager
config.h                 keybindings, rules, autostart, colours (compiled in)
config.mk                build flags
config/quickshell/       the bar: 22 QML files
  shell.qml                entry point
  core/                    shared visuals and singletons, including Theme.qml
  panel/                   the bar and its items
  services/                the optional indicators
  state/DwmState.qml       the bridge to dwm
config/rofi/             launcher, power menu, repo finder, bookmarks
config/gtk-3.0/, gtk-4.0/  the dark theme for GTK applications
scripts/                 installed to ~/.local/bin; .xinitrc and .xprofile to $HOME
tools/qml-lint.sh        offline qmllint wrapper
tests/                   one script per contract
debug/                   EWMH inspection helpers
backgrounds/             wallpapers
install.sh               standalone installer
```

The bar reads the window manager's state through standard EWMH root properties
plus a few `_DWM_*` properties this build adds, published by
`scripts/dwm-quickshell-state`. That script and the bar share a line-oriented
record format documented in `SPEC.md`; a change to one is a change to both.

## Troubleshooting

**The bar does not appear.** Check that `quickshell` is installed, then run
`~/.local/bin/quickshell-launch.sh` from a terminal — it names any missing
dependency rather than failing silently.

**Clicking workspaces or applications does nothing.** `wmctrl` is missing.

**The bar's application dock and tray are empty.** You are on an icon theme with
no application icons. Install `papirus-icon-theme` and select `Papirus`, not
`Papirus-Dark`.

**The bar is tiny on a 4K screen.** See [HiDPI and 4K
screens](#hidpi-and-4k-screens). Confirm the value is live with
`xrdb -query | grep Xft.dpi`.

**No dwm option at the login screen.** `sudo make install` writes
`/usr/share/xsessions/dwm.desktop`, but only if it is not already there. Check
that the file exists.

**An indicator is missing.** That is deliberate: each one hides itself when its
hardware or its tool is absent. See the optional packages in
[Requirements](#requirements).

**GTK applications come up light.** Check that
`~/.config/gtk-3.0/settings.ini` names `Adwaita` and not `Adwaita-dark`. GTK 3
has no theme by that name — it carries Adwaita as a compiled-in resource with
separate light and dark stylesheets, and `gtk-application-prefer-dark-theme` is
what picks the dark one. `Adwaita-dark` resolves to nothing, GTK falls back to
light, and `gtk-theme-name` reads back exactly as written, so the setting looks
applied. GTK 4 does resolve the name, which is why `config/gtk-4.0/settings.ini`
differs on purpose.

**A monitor is on the wrong side.** See [Monitor
arrangement](#monitor-arrangement).

**A power menu entry does nothing.** It should now say why in a rofi dialog.
Suspend and hibernate are only offered when `/sys/power/state` names them;
hibernate additionally needs swap at least the size of RAM and a `resume=`
kernel parameter.

### Bookmarks menu

The bookmarks menu (`Super + Ctrl + Shift + b`) reads a bookmarks file. To
generate one from a browser export, put `bookmarks.html` in the current
directory and run:

```bash
bash <(curl -fsSL https://gist.githubusercontent.com/gameshler/02baf4689dd9bafb824a53c931b75c4a/raw/dwm-bookmark-parser.sh)
```

## License

MIT/X Consortium License. See [LICENSE](LICENSE) for the full text and the
copyright holders, who include the upstream dwm authors.
