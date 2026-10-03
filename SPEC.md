# Project specification

## Problem

The desktop ran polybar. Polybar cannot show what this dwm build actually
knows: it has no real notion of dwm tags, so tag state came from a shell script
polling `xprop` and rendering text, and anything richer than text was out of
reach. Replacing it with a Quickshell bar moves the bar to a real QML toolkit,
which makes tray icons, per-app icons, tooltips and click targets possible
instead of glyph strings.

## Users

The repo owner, running this as a daily driver. One person, one machine class:
Arch-based, x86_64, Xorg. Other people cloning the repo are a secondary
audience served by `README.md` and `install.sh`.

Constraints that follow from that: no packaging, no release cadence, and no
tolerance for a bar that fails silently. When something breaks, the user sees a
broken desktop on the machine they work from.

## Required behavior

The bar shows, and keeps current:

- Tag buttons for every tag, marking which are viewed, which are occupied, and
  which hold an urgent client.
- The focused window's title, falling back to `Desktop` when nothing is
  focused.
- One icon per running application, deduplicated by window class, dock style.
- A system tray.
- A clock.
- The root window's status line, one segment per field, when a status program
  is writing one. Nothing at all when none is.
- A count of pending package updates, hidden when there are none.
- Optional pills for audio, battery, bluetooth and network.

Interaction:

- Clicking a tag button views that tag.
- Clicking an application icon focuses that window, switching the viewed tag
  first when the window is on a tag that is not being viewed.
- Left-clicking the volume pill opens `pavucontrol`. Scrolling it changes the
  volume; middle-clicking mutes.
- Clicking the update pill opens a terminal running `pacman -Syu`.
- Clicking the power pill opens the rofi power menu.

Error, empty and recovery behavior:

- Each optional pill hides itself when its backing tool is missing.
  `nmcli`, `bluetoothctl` and `pavucontrol` are all optional at runtime.
- With no windows open, the title reads `Desktop` and the class falls back to
  `application-x-executable`.
- `dwm-quickshell-state watch` is the bar's state feed. If it dies, the bar
  restarts it. The watcher must not be assumed to be long-lived.
- `focus` and `switch` reject an argument that is not a hex window id or a
  decimal workspace index, exiting 2 without running anything.

## User experience

One bar, at the top, on every monitor. Tag buttons on the left, title beside
them, running apps next, then tray, pills and clock on the right.

Accessibility is out of scope. Layout has two requirements.

The bar must render correctly on a multi-monitor setup, because the target
machine has one. `_DWM_MONITOR_DESKTOPS` and `_DWM_SELECTED_MONITOR` exist so
the bar can tell its monitors apart.

The bar must also hold its layout at any screen size, from a 1024-wide netbook
to a 32:9 ultrawide, and at any number of open windows. Four rules follow from
that, because all four were broken:

- The window title yields before anything else. It is the only compressible
  thing in the left group, so a long title elides instead of overprinting the
  centre clock.
- The app dock has a ceiling, expressed as a share of the bar rather than a
  pixel count. Windows past the ceiling are counted, not drawn. Nothing to the
  right of the dock - the tray, the indicators, the power button - may ever be
  pushed off the screen.
- The status line is drawn when the room left over will hold it and dropped
  when it will not. That is a measurement against the status line actually
  being written, not a screen width chosen in advance: the same 1366 laptop
  keeps a short status line and drops a long one.
- Sizes are logical pixels and scale through the screen's device pixel ratio.
  Text is hinted when that ratio is a whole number and drawn from a scalable
  distance field when it is not.

## Architecture and data flow

State flows one way, dwm to bar:

```
dwm  -> X root properties  -> dwm-quickshell-state watch -> DwmState.qml -> bar
```

`dwm-quickshell-state` owns all state reading. It watches nine root properties
with a single long-lived `xprop -spy`, plus a second spy on the focused
window's title, and emits one record per real change. It suppresses a record
identical to the one before it, so an X event that changes nothing produces no
output.

The record is newline-separated `key=value`, twelve keys, in this order:

```
current=              viewed tag, zero-based
monitor_desktops=     per-monitor viewed tags, comma separated, no spaces
focused_monitor=
count=                number of tags
names=
occupied=             tags holding at least one client
fullscreen_monitors=
apps=                 id:class pairs, pipe separated, lower case, deduped
active_window=        hex window id
title=                falls back to Desktop
class=                falls back to application-x-executable
status=               root window WM_NAME, empty when unset
```

`status` is the classic dwm status line, the thing `xsetroot -name` writes and
dwm's own bar renders. This build uses an alt bar, so the Quickshell bar reads
it and splits it on `" | "` or a run of two or more spaces, one pill per field.
`WM_NAME` rides along in the existing batched read and the existing root spy,
so it adds no process and no event; with no status program running the property
is absent and the bar shows nothing.

Commands flow the other way, bar to dwm, through `wmctrl`:

```
dwm-quickshell-state switch <zero-based-tag>
dwm-quickshell-state focus  <hex-window-id>
```

State ownership: dwm is the single source of truth. The bar holds no state the
watcher did not give it, and never writes X properties directly.

This build patches `clientmessage()` so `_NET_ACTIVE_WINDOW` is honoured when
the EWMH source indication says a pager sent it, and still flagged urgent when
an application asked for itself. Vanilla dwm flags every request urgent and
focuses none, which is why `wmctrl -ia` from the bar did nothing.

`config.h` `autostart[]` launches `display-setup.sh` and `quickshell-launch.sh`
by absolute path under `$HOME/.local/bin`.

## Security and privacy

- One thing in this repo reaches the network at runtime: the update pill runs
  `checkupdates` every thirty minutes. `checkupdates` syncs a private copy of
  the package database under `$TMPDIR`, so it never touches the real one and
  never leaves a partially synced system behind. Without `pacman-contrib` it
  falls back to `pacman -Qu`, which is offline. Nothing else in the bar makes a
  network call; `install.sh` calls `pacman`, which is the only other one.
- `install.sh` runs as the normal user and calls `sudo` only for `pacman` and
  `make install`. It refuses to run as root.
- `dwm-quickshell-state` takes two arguments from the bar and passes them to
  `wmctrl`. Both are validated against a strict pattern before use; anything
  else exits 2. This is the only place external input reaches a command line.
- No credentials, tokens or personal data belong in this repo. `.qmlls.ini`
  holds machine-local absolute paths and is gitignored for that reason.

## Performance and compatibility

Supported: Arch-based distributions, x86_64, Xorg, Quickshell as packaged in
the Arch repos. Not supported: Wayland, other distributions, other
architectures.

Budgets for the state watcher, measured on a three-window desktop:

| | budget |
| --- | --- |
| Processes forked per state read | at most 30 |
| Records emitted at bar startup | 1 |
| Records emitted per user action | 1 |
| Records emitted while idle | 0 |
| Settled CPU while idle | 0.0% |

The idle numbers are the important ones. A bar that wakes up when nothing
happened is a battery bug on a laptop.

## Non-goals

- Wayland. This is an Xorg window manager.
- Supporting window managers other than this build. The bar reads `_DWM_*`
  properties that only exist here.
- A unit-test framework, or coverage as a target. `tests/` holds contract
  tests, not unit tests: most of them read source and assert something this
  document or a header comment already claims, two run a script for real
  against stubs on `PATH`, and one runs dwm and the bar under Xvfb. Behaviour
  on the real machine is still proven by using it.
- Packaging, versioned releases, or upgrade migration paths.
- Theming beyond the single theme in `core/Theme.qml`.
- Reimplementing the polybar modules that were dropped rather than carried over.

## Acceptance criteria

Automated, and required before any change is reported done:

- `make CC="cc -Werror"` succeeds with zero warnings under the `-Wextra` set in
  `config.mk`.
- `make lint` reports zero shellcheck findings, zero shfmt diff lines, and zero
  qmllint warnings across all 22 QML files.
- All four CI jobs pass: `build`, `shell`, `qml`, `tests`.

Manual, and required before the branch merges:

- The bar renders on the target hardware, with every module present.
- Clicking a tag switches tags. Clicking an app icon focuses that window,
  including when the window is on another tag.
- Killing `dwm-quickshell-state` with `SIGKILL` results in the bar restarting
  it and state resuming.
- `./install.sh` on a clean Arch install produces a working desktop.
- The state watcher meets the idle budgets above: zero records and no
  measurable CPU on an untouched desktop.

## Decisions

- `install.sh` does not install a display manager. It detects an enabled one
  and reports it, and otherwise points at `startx` with the `.xinitrc` the
  install target already placed. Which login manager a machine runs is the
  owner's choice, not this repo's.
- `config.h` is tracked and is no longer listed in `.gitignore`. The entry was
  dead - tracking wins over an ignore rule - and keeping the file tracked is
  what makes a clone carry the real keybindings.
- HiDPI scaling is driven by `Xft.dpi` and nothing else. `scripts/.xprofile`
  loads `~/.Xresources`, and `scripts/quickshell-launch.sh` translates the value
  into `QT_FONT_DPI` for the bar. One setting scales dwm's font, rofi and the
  bar together.

  The bar does not derive its scale from the screen, and deliberately so.
  Measured under Xvfb on Qt 6.11: Qt on xcb ignores both `Xft.dpi` and the
  physical dimensions the X server reports, and hands QML a flat 96 DPI through
  `logicalPixelDensity` on every screen, with `physicalPixelDensity` being only
  96 divided by the device pixel ratio. Neither carries any information about
  the real panel, so a scale computed from them would be a no-op presented as a
  measurement. `QT_FONT_DPI` and `QT_SCALE_FACTOR` were the only two mechanisms
  that moved the ratio at all.

  Qt's default scale rounding policy is left at `PassThrough`, so fractional
  ratios reach the bar rather than being rounded to whole numbers. Rounding
  would make every glyph hintable, but it would also size the bar differently
  from the GTK applications beside it on a 150% display. The text renderer
  handles the fractional case instead.
