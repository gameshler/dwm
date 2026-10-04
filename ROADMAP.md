# Project roadmap

Phases 1 and 2 are built and their automated gates pass. Neither has been run on
the target hardware yet, so neither is finished. Phase 3 is where that happens.

## Phase 1: Bar swap

### Outcome

Polybar is gone and a Quickshell bar shows tags, title, running apps, tray,
clock and the optional pills, fed by a single state script.

### Included work

- Delete `config/polybar/` in full, including its bundled fonts.
- Add `config/quickshell/`: `shell.qml` plus `core/`, `panel/`, `services/` and
  `state/`.
- Add `scripts/dwm-quickshell-state` as the only state source, and
  `scripts/quickshell-launch.sh` as the `autostart[]` entry point.
- Point `autostart[]` in `config.h` at the launcher by absolute path.
- Add `tools/qml-lint.sh` so qmllint can resolve the `qs.*` modules offline.
- Add `install.sh` and rewrite the `README.md` install section around it.
- Teach `make install` to place `scripts/*` in `~/.local/bin` with the real
  user as owner rather than root.
- Widen `config.mk` to `-Wextra` with three documented suppressions.
- Add the `build`, `shell` and `qml` CI jobs.

### Dependencies and risks

- Deleting `config/polybar/` is destructive and cannot be undone from the
  working tree once committed. It is recoverable from history.
- Quickshell's QML API is unversioned upstream. A Quickshell update can break
  the bar with no warning and no deprecation period. This is the standing risk
  of the whole phase and there is no mitigation beyond noticing quickly.
- `make install` writing to `~/.config` and `~/.local/bin` can overwrite a
  hand-edited config. It refreshes only the files this repo ships.

### Exit criteria

- The bar renders every module on the target hardware.
- No polybar file, font or launcher remains anywhere in the tree.
- `./install.sh` on a clean Arch install produces a working desktop.

### Validation

- Automated: `make CC="cc -Werror"` clean, `make lint` clean, all three CI jobs
  green. DONE.
- Rendered evidence: bar screenshotted under Xvfb in a container. DONE.
- Manual on hardware: DONE in part. The bar renders every module on the target
  hardware, which is this phase's first exit criterion. It also surfaced seven
  defects, carried into Phase 4.
- Clean-install run of `install.sh`: DONE. It produced a working desktop on an
  Arch machine, with the caveats now fixed in Phase 4.

## Phase 2: Make the bar actually work

### Outcome

Clicking things in the bar does what it looks like it does, and the bar costs
nothing when the desktop is idle.

### Included work

- Patch `clientmessage()` in `dwm.c` to honour `_NET_ACTIVE_WINDOW` from a
  pager, using the EWMH source indication, and keep flagging an application
  that asks for itself. Switch the viewed tag first when the target is not
  visible.
- Rewrite `dwm-quickshell-state` around one batched root-property read and one
  long-lived spy, replacing the per-property `xprop` calls.
- Deduplicate identical consecutive records so an X event that changes nothing
  emits nothing.
- Drop the initial `xprop -spy` property dump so the bar gets one record at
  startup rather than nine.

### Dependencies and risks

- Depends on Phase 1. There is nothing to click before the bar exists.
- The `dwm.c` change makes dwm honour a focus request it used to refuse. A
  misbehaving application that sends a pager-shaped request can now steal
  focus. The source indication check is the whole defence.
- The state script rewrite changed the record format in one way: double spaces
  inside a window title are preserved now. The old collapse existed to flatten
  multi-line values that `xprop` never actually emits.

### Exit criteria

- Clicking an app icon focuses that window, on the current tag and across tags.
- The watcher meets every budget in `SPEC.md`, including zero idle records.
- The rewrite produces the same records as the version it replaced, except
  where the old version was wrong.

### Validation

- Automated: same gates as Phase 1, plus a negative control proving the
  `-Werror` build actually rejects a warning. DONE.
- Differential test, old script against new, across seven window states: six
  byte-identical, one where the new script is correct. The old one truncated
  any title containing `= `. DONE.
- Measured under Xvfb: 103 forks per read down to 26, eleven startup records
  down to one, four to five records per action down to one, zero idle records
  in both. DONE.
- Injection refused on `focus` and `switch`, exit 2. DONE.
- Manual on hardware: NOT DONE for the interaction criteria - tag clicks,
  cross-tag focus, watcher respawn and the idle budget were not exercised by
  the first install. Blocks this phase.

## Phase 3: Release readiness

### Outcome

The work is on `main`, in commits that can be read one at a time, and the
archsetup dwm tab installs against it correctly.

### Included work

- Split the working tree into atomic commits. It currently holds six unrelated
  logical changes: the bar swap, the `dwm.c` focus fix, the installer, the
  `-Wextra` widening, the CI and lint tooling, and the shell script fixes.
- Resolve the two open questions in `SPEC.md`: the display manager step and the
  `config.h` `.gitignore` entry.
- Run the manual validation that Phases 1 and 2 are both waiting on.
- Open the pull request and merge.

### Dependencies and risks

- Merge ordering is load-bearing. Every archsetup path reads this repo's
  `main`: its dwm tab clones it, and its ghostty and rofi steps `curl`
  individual files from it. This repo must merge before archsetup PR #21, or
  the tab installs Quickshell packages onto a polybar config.
- The tree carries 40-odd polybar deletions staged alongside untracked new
  directories. Splitting it into clean commits is the fiddly part, not the
  risky part.
- No commit or push authorization has been given for this repo yet.

### Exit criteria

- Every commit builds and lints on its own.
- Manual hardware validation for Phases 1 and 2 recorded as passed.
- Both open questions in `SPEC.md` answered.
- Merged, and archsetup PR #21 merged after it.

### Validation

- The full local gate on the final tree, plus CI green on the pull request.
- Manual hardware testing, documented in `TASKS.md` with what was exercised.
- A clean-install run of `install.sh`.
- Rollback: revert the merge commit. Nothing in this repo holds state, writes a
  database, or migrates anything, so a revert plus a re-run of `install.sh`
  restores the previous desktop.

## Phase 4: The defects the first install found

### Outcome

The desktop the install produces is the one it was meant to produce: dark
throughout, readable on the author's two monitors, sharp, current, and with
every control doing what it says.

### Included work

- Name a GTK 3 theme that resolves, so GTK 3 applications come up dark.
- Enlarge the bar and put every dimension on whole pixels, choosing icon sizes
  the icon theme actually draws.
- Lift body text to meet the WCAG AA contrast floor against the black bar.
- Refresh the update count from a watch on pacman's log rather than only from
  a half-hourly timer.
- Repair the power menu: resolve the session rather than assuming one, offer
  only the sleep states the kernel accepts, and report every failure.
- Repair `display-setup.sh`: read the refresh rate from the output's own mode
  block, and take the left-to-right arrangement from a layout file.

### Dependencies and risks

- Nothing here changes `dwm.c` or the state protocol, so the parts carrying
  real risk are untouched. The blast radius is the bar's appearance, two
  scripts, and one settings file.
- Two of the six are repairs to code that demonstrably never worked, which
  means there is no behaviour to regress.
- `Theme.qml` sets sizes everywhere at once; a mistake there is visible
  immediately and everywhere, which is the good case.

### Exit criteria

- Each of the seven reported defects is confirmed fixed on the machine that
  reported it.
- The interaction criteria Phases 1 and 2 are still waiting on are exercised
  on that machine.

### Validation

- The full local gate: `make CC="cc -Werror"`, `make lint`, `make check`.
- Both shell defects reproduced against the previous script before the fix,
  and pinned by a test afterwards.
- The GTK 3 defect measured as a rendered colour rather than argued about.
- Rendered evidence: the bar screenshotted before and after at 2560x1440.
- Rollback: revert the merge commit and re-run `install.sh`. Nothing here
  holds state.

## Phase 5: The menus move into the bar

The power menu, the project finder and the bookmarks menu were three rofi
scripts. They are now three surfaces of the running bar, opened over IPC.

Why: the power menu was the one piece of this desktop that had never fully
worked, and the shell-and-rofi shape was most of the reason. A menu that is
part of the bar shares its theme, reports its own failures on screen instead of
to a stderr nobody reads, and needs no second toolkit to be themed and kept in
step.

The load-bearing constraint: Quickshell's panels and popups are
`_NET_WM_WINDOW_TYPE_DOCK` on X11, and dwm does not focus a dock, so a menu
built that way cannot take a keystroke. The menus are therefore ordinary managed
windows with a `rules[]` entry that floats them. dwm fixes a floating client's
geometry when it first manages it, so each menu's window is created on open and
destroyed on close rather than reused.

Exit criteria:

- Each of the three keybindings opens and closes its menu.
- The menu takes keyboard focus with no click, and filters, navigates, acts and
  dismisses from the keyboard alone.
- A failing power action states its reason on the menu.
- The rofi scripts they replace are gone, and rofi remains only as the
  application launcher.
