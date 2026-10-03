# Project instructions

## Purpose

A patched [dwm](https://dwm.suckless.org) build plus the desktop config that
surrounds it: a [Quickshell](https://quickshell.org) status bar, rofi menus,
ghostty, picom and dunst. The user is the repo owner running it as a daily
driver on an Arch-based x86_64 machine under Xorg. Cloning the repo and running
`./install.sh` should produce that working desktop.

## Architecture

- `dwm.c`, `drw.c`, `util.c`, `config.h`, `config.mk` - the window manager.
  `config.h` is the real configuration and is tracked; `config.def.h` is the
  upstream default the Makefile would copy if `config.h` were absent.
- `config/quickshell/` - the bar, 22 QML files in four groups. `shell.qml` is
  the entry point. `core/` holds shared visuals and singletons, `panel/` the
  bar and its items, `services/` the optional pills (audio, battery,
  bluetooth, network, updates), `state/DwmState.qml` the bridge to dwm.
  `core/Theme.qml` is the single source of every colour and dimension; its
  header explains the design rules the rest of the bar follows.
- `config/gtk-3.0/`, `config/gtk-4.0/` - the dark theme for GTK applications,
  read directly by GTK because dwm runs no XSettings manager.
- `scripts/` - installed to `~/.local/bin`. `dwm-quickshell-state` is the bar's
  only source of window-manager state. `quickshell-launch.sh` is what
  `autostart[]` in `config.h` runs; it prepends `~/.local/bin` to `PATH` so the
  bare-name calls in `DwmState.qml` resolve. `.xinitrc` and `.xprofile` are the
  exception: the `install` target copies them to `$HOME`, not to
  `~/.local/bin`, and never over an existing one.
- `tools/qml-lint.sh` - rebuilds Quickshell's runtime `qs.*` module tree in a
  temp directory so qmllint can run offline, with no X server and no running
  shell.
- `config/rofi/`, `debug/`, `backgrounds/` - menus, EWMH debug helpers,
  wallpapers.
- `install.sh` - standalone installer. `Makefile` `install` target - the file
  copies only, used by `install.sh` and by the archsetup dwm tab.
- `.github/workflows/c.yaml` - four jobs: `build`, `shell`, `qml`, `tests`.
- `tests/` - one script per contract, each with its own `make check-<name>`
  target. `make check` runs the lot.

Generated or machine-local, never hand-edited: `dwm` and `*.o`, `config.h` when
it does not exist, `.qmlls.ini`, and `.context/` scratch work.

External interfaces this repo depends on:

- EWMH root properties plus the `_DWM_*` properties this build adds, read with
  `xprop` and written with `wmctrl`.
- Quickshell's QML API, which is not versioned upstream and does break.

Toolchain: `cc`, `make`, `shellcheck`, `shfmt`, `qmllint` from
`qt6-declarative`. Target environment: Arch-based, Xorg, x86_64.

## Working boundaries

- Preserve unrelated changes. The working tree often carries in-progress work
  from more than one line of effort.
- Do not expose or commit credentials, sessions, private data, or environment
  files.
- Require authorization for destructive operations, migrations, and
  deployments; reuse authorization already given. Ask about unresolved product
  or architecture decisions only when they materially affect the result.
- `dwm.c` deviates from upstream in documented places. When changing it, say
  what upstream does and why this build differs, in a comment at the change.
- The bar and `dwm-quickshell-state` share a line-oriented record format. A
  change to one is a change to both; see the protocol in `SPEC.md`.

## Commands

```bash
make                        # build dwm
make CC="cc -Werror"        # the build gate CI runs
make lint                   # shellcheck -x, shfmt -d, then tools/qml-lint.sh
make check                  # the tests/ suite
make check-layout           # one test on its own; see the Makefile for the list
make clean
sudo make install           # needs root for /usr/local/bin and /usr/share/xsessions
./install.sh                # packages, build, sudo make install, wallpapers
```

`make install` writes the binary to `${PREFIX}/bin`, the man page to
`${MANPREFIX}`, and a session entry to `/usr/share/xsessions`, so it needs
root. It reads `USER_HOME` and `OWNER`, defaulting to `SUDO_USER` when set and
`USER` otherwise, so the `~/.config` and `~/.local/bin` halves still land in the
real user's home under `sudo`. Override both to install somewhere else:

```bash
make install USER_HOME=/home/tester OWNER=tester
```

`make lint` discovers shell scripts with `shfmt -f` over `config debug scripts
tests tools install.sh`, so a new script is covered without editing the target.
The `shell` job in CI uses the same discovery set. Any qmllint warning fails the
run.

## Validation

- Run focused checks while implementing.
- Run the complete required local gate before reporting done: `make CC="cc
  -Werror"` with zero warnings, then `make lint` with zero findings and zero
  diff lines, then `make check` with every test passing.
- Inspect the final status and diff.
- Verify visible behavior with screenshots or equivalent rendered evidence. A
  bar change is not verified until the bar has been seen rendering.
- `tests/` holds the suite. Most of it reads source and asserts a contract
  that is documented somewhere - SPEC.md, a header comment - so it costs no X
  server and belongs next to the linters. `test-quickshell-launcher.sh` and
  `test-dwm-quickshell-state.sh` run the real scripts against stubs on `PATH`.
  `test-bar-xvfb.sh` runs dwm and the bar for real and exits 77, which the
  Makefile treats as a skip, when Quickshell or Xvfb is absent.
- A test that only restates an edit is not worth adding. Add one when a
  contract spans two files, when a defect was reproduced before being fixed,
  or when the failure would otherwise be silent.
- The suite does not replace running the thing. Behavior on hardware is proven
  by running dwm and the bar there; under Xvfb in a container otherwise. Say
  which one was used.
- Report skipped checks and unresolved manual testing explicitly.

## Documentation routing

- Read `SPEC.md` for requirements and acceptance criteria.
- Read `ROADMAP.md` for phase order and exit criteria.
- Read `TASKS.md` for current work and validation status.
- `README.md` is the user-facing install and development guide.
