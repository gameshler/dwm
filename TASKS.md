# Project tasks

Current phase: Phase 5, the menus move into the bar. See `ROADMAP.md`.

## Current phase

- [ ] Run the four bar menus on hardware.
  - Scope: the apps, power, projects and bookmarks menus on
    `gameshler/feat/quickshell-menus`, which replace rofi entirely.
  - Acceptance criteria: each keybinding opens its menu and the same key closes
    it; the menu takes keyboard focus immediately, with no click; typing
    filters, the arrows move, Enter acts and Escape dismisses; the apps menu
    lists every installed application with its own icon and starts the one
    picked, wrapping a `Terminal=true` entry in ghostty; every power entry
    either acts or says why on the menu; a project with a space in its name
    opens; a work bookmark opens in Brave and a personal one in Firefox; the
    bar keeps showing the real focused window's title while a menu is open.
  - Automated validation: passed - `make CC="cc -Werror"` zero warnings,
    `make lint` zero findings, `make check` ten of ten.
    `tests/test-menus-xvfb.sh` drives all four menus through IPC and the real
    keyboard under Xvfb and asserts what each one executed;
    `tests/test-session-action.sh` covers the helper against stubs.
  - Manual validation: is the task. A container cannot prove a real logout, a
    real suspend, that Brave and Firefox are the browsers that open, or that the
    installed icon theme has an icon for every application on this machine.
  - Dependencies or blockers: stacked on `gameshler/fix/post-install-defects`
    (pull request #3), which must merge first.

- [ ] Remove the rofi step from the archsetup dwm tab.
  - Scope: `core/tabs/apps/dwm/rofi-setup.sh` in the archsetup repository, and
    the menu entry that offers it.
  - Why: that script installs the rofi package and `curl`s five files out of
    `config/rofi/` on this repository's `main`. All five are gone, so the step
    now writes empty files and installs a package nothing calls.
  - Acceptance criteria: the dwm tab no longer offers a Rofi step, and a run of
    the tab on a clean machine leaves no `~/.config/rofi`.
  - Dependencies or blockers: belongs to archsetup, not here, and must land
    before or with this repository's merge to `main`.

- [ ] Re-verify the nine hardware defects on the machine they were found on.
  - Scope: the fixes on `gameshler/fix/post-install-defects`, installed and
    exercised on the same two-monitor Arch machine that reported them.
  - Acceptance criteria, one per defect: GTK 3 applications come up dark;
    the bar reads comfortably on both the 1080p and the 1440p panel; icons and
    the clock are sharp; the update count changes within seconds of a `pacman`
    transaction rather than within half an hour; every power menu entry either
    acts or says why; a monitor named first in `~/.config/dwm/monitors.conf`
    is the one on the left; hovering a tag, a dock icon or a pill shows a
    fill, and the bar has a visible bottom edge over a black wallpaper;
    `Super + p` and `Super + Shift + p` leave a file in
    `~/Pictures/Screenshots` with no drive mounted.
  - Automated validation: passed already - `make CC="cc -Werror"` zero
    warnings, `make lint` zero findings, `make check` nine of nine including
    renders at 40 physical pixels across five widths and 60/80 at ratios 1.5
    and 2. Both shell defects were reproduced against the previous scripts
    before being fixed, and the GTK 3 defect was measured as a colour.
  - Manual validation: is the task. None of it can be proven here - a
    container has no GPU, no logind session, no monitors and no pacman
    transactions.
  - Dependencies or blockers: none.

- [ ] Finish the parts of the Phase 1 and 2 gate the first install did not
      cover.
  - Scope: the acceptance criteria below that the hardware run never
    exercised. The install itself, the bar rendering and every module being
    present are confirmed.
  - Acceptance criteria, still unproven on hardware: clicking a tag switches
    tags; clicking an app icon focuses that window on the current tag and
    across tags; `kill -9` on `dwm-quickshell-state` has the bar restart it;
    an untouched desktop shows no measurable CPU; the dock icons draw
    greyscale and return to colour under the pointer on a real GPU; the title
    and tooltips render in Inter; the update pill's click opens a terminal;
    `Xft.dpi: 192` scales the bar along with dwm's font.
  - Automated validation: none applies. This is the gate automation cannot
    cover.
  - Manual validation: is the task.
  - Dependencies or blockers: none.

## Completed in Phase 3

- [x] Run the manual hardware validation Phases 1 and 2 are both waiting on.
  - Run on the author's two-monitor Arch machine. The install completed, the
    bar came up, and every module rendered - which is the core of what Phases
    1 and 2 could not prove in a container.
  - It found seven defects, four of which no container could have caught and
    three of which had never worked at all:
    - GTK 3 applications came up light. `gtk-theme-name=Adwaita-dark` names a
      theme GTK 3 does not have, so it fell back to light Adwaita while
      reading the name back unchanged. Measured as `theme_bg_color` #F6F5F4
      against #353535.
    - The bar was too small to read comfortably at 32 logical pixels across a
      1080p and a 1440p panel.
    - Icons were soft. `trayIconSize` 17 centred in a 24 box is an offset of
      3.5 physical pixels, and 17 is not a size any icon theme draws.
    - The clock was soft, from `letterSpacing: 0.8` under a renderer that
      hints glyphs onto the pixel grid.
    - The update count stood still for up to thirty minutes after a system
      update, which is the one moment it is certainly wrong.
    - The power menu's logout never worked. It passed `$XDG_SESSION_ID` to
      `loginctl` unconditionally, and a display manager does not reliably
      export it.
    - `display-setup.sh` had never configured anything. It read the refresh
      rate by grepping the whole `xrandr` query for the resolution, which also
      matches the output's `connected` header, so a 2560x1440 panel yielded
      "597" - its width in millimetres - and `xrandr` refused the command. It
      also arranged monitors by connector name, which is unrelated to where
      they sit.
  - Body text also measured 4.30:1 against the black bar, under the 4.50:1
    WCAG AA floor, which is consistent with the eye strain reported.
  - The criteria it did not exercise are carried forward as the second open
    task above.

- [x] Split the working tree into atomic commits. Eleven commits, merged in
      pull request #2.
- [x] Open the pull request and merge before the archsetup pull request.
      dwm #2 merged, then archsetup #22.

## Built, pending manual validation

These are implemented, their automated gates pass, and the hardware run has
now covered part of what they were waiting on: the install, the bar coming up
and every module rendering are confirmed on the machine. What that run did not
exercise is listed as the second open task above, and the defects it did find
are listed with it.

This section is kept as the record of what each piece was proven to do before
it reached hardware, and by what means.

- Bar swap. Polybar deleted, `config/quickshell/` added with 19 QML files,
  `dwm-quickshell-state` and `quickshell-launch.sh` added, `autostart[]`
  repointed, `make install` placing scripts with the right owner.
  - Passed: `make CC="cc -Werror"` zero warnings under `-Wextra`; `make lint`
    zero findings, zero diff lines, zero qmllint warnings across 19 files; the
    steps the three CI jobs run, reproduced locally in an Arch container; bar
    screenshotted rendering under Xvfb; `make install` as non-root producing
    correct paths and ownership.
  - Not passed, because it cannot be yet: CI itself. The branch has no commits
    for this work and has never been pushed, so no workflow run exists.
- `dwm.c` focus fix. `clientmessage()` honours `_NET_ACTIVE_WINDOW` from a
  pager via the EWMH source indication, views the target's tag first when it is
  not visible, and still flags an application that asks for itself.
  - Passed: same-tag focus; focus switching back; cross-tag focus snapping the
    view to the target's tag; injection into `focus` and `switch` refused with
    exit 2.
- `dwm-quickshell-state` rewrite. One batched root-property read, one
  long-lived spy, consecutive-duplicate suppression, initial property dump
  drained rather than emitted.
  - Passed: 103 forks per read down to 26; eleven startup records down to one;
    four to five records per action down to one; zero idle records; 0.0%
    settled CPU; watcher respawns after `kill -9`; differential test against
    the previous version byte-identical on six of seven window states.
  - The seventh differed because the old version was wrong: its `awk -F'= '`
    truncated any title containing `= `. Fixed by the rewrite.
- Black bar redesign, and the two widgets the bar was missing.
  `core/Theme.qml` reground onto `#000000` with Nord accents kept; every pill
  transparent at rest; tags and the app dock switched from boxes to a two pixel
  accent underline; `core/PanelSeparator.qml` added; `config.h` client borders
  matched; the rofi theme matched. New: a `status` key in the record, carrying
  the root window's `WM_NAME`, rendered one pill per field, and
  `services/UpdateModel.qml` for the pending-update count.
  - Passed: `make CC="cc -Werror"` zero warnings; `make lint` zero findings
    across 21 QML files; the bar screenshotted under Xvfb showing tag marks,
    the status segments fed by a real `xsetroot -name`, the update pill, and
    the app dock dimming every icon but the focused one.
  - `WM_NAME` rides the existing batched read and the existing root spy, so the
    idle budgets in `SPEC.md` are unchanged. `checkupdates` is the one thing in
    the repo that now reaches the network at runtime, every thirty minutes;
    that inverts a `SPEC.md` invariant and is recorded there.
- Design fixes to the black bar, from reviewing the render against the rest of
  the palette. The tag numerals and the dock icons were two pixels above every
  other baseline in the bar, because the mark under them was made by lifting
  the glyph rather than by hanging the mark off the bottom of the cell. The
  dock drew Papirus icons in full colour, the only saturated thing on a bar of
  grey plus one accent; they are greyscale now, through a `MultiEffect` on the
  icon layer, and return to colour under the pointer. The window title and the
  tooltips were set in the terminal font, which made the title read as program
  output; `core/ProseText.qml` sets them in Inter. The separator between the
  tags and the title is gone, because the group gap already read as a break.
  - Passed: `make CC="cc -Werror"` zero warnings; `make lint` zero findings
    across 22 QML files; ink density measured row by row, tags and clock both
    on rows 11-19 where they differed by two before; the bar rendered under
    Xvfb on llvmpipe, which runs the real OpenGL path so the shader actually
    executes, with a pointer sweep across the dock for the hover state.
  - `inter-font` is a new required package, 3.5 MiB from `extra`. The family
    chain is resolved at startup against `Qt.fontFamilies()`, ending at the
    mono font the installer already guarantees, because QML's font value type
    has only `family`, no `families`.
- Resolution and HiDPI. The bar held its layout only around 1366 to 2560 with
  few windows open. Three defects, all reproduced before being fixed: a long
  window title overprinted the centre clock at 1280 and below; the app dock had
  no ceiling, so twelve windows on a 1024 screen ran it off the right edge and
  took the tray and the power button with it; and nothing scaled on a HiDPI
  panel. Now the title is the only compressible thing in the left group, the
  dock is capped at a share of the bar and counts what it cannot draw, both
  side groups claim the same width so the clock stays centred, and the status
  line is drawn only when the room left over measures wide enough to hold it.
  That last rule started as a hand-picked 1400px threshold, which was wrong in
  both directions - it dropped the status on a 1366 laptop that had room and
  would have kept it on a wider screen running a longer status line. It is now
  anchored in the right-hand slack rather than being a layout child, so the
  measurement cannot feed back into the width it is measuring, and the width it
  needs is read off `TextMetrics` rather than off the row that draws it, which
  reports nothing while hidden. Sharpness was a separate
  bug: `layer.textureSize` on the dock icons defaults to logical pixels, so the
  greyscale layer rendered at 17px and was stretched on a HiDPI screen.
  - Passed, measured in an Arch container on llvmpipe: `make CC="cc -Werror"`
    zero diagnostics and `make lint` zero findings; renders at 1024x600,
    1280x720, 1366x768, 1920x1080, 2560x1440, 3440x1440, 5120x1440 and
    3840x2160 with no overlap and nothing clipped; 12 windows at 1024 showing
    six icons and `+6`, 16 windows at 1366 showing eight and `+8`, the power
    button present in both; bar height 32, 48 and 64 physical pixels at device
    pixel ratios 1, 1.5 and 2.
  - The measured status fit was verified against the case a fixed threshold
    cannot tell apart: the same 1366x768 bar keeps a three-segment status line
    and drops a six-segment one, and 1024x600 keeps the three-segment line with
    two windows open but drops it with twelve, because by then the dock has
    taken the room. 2560 draws the six-segment line in full.
  - The icon sharpness fix was measured rather than eyeballed: a
    halve-then-double round trip on the 2x render scores RMSE 7784 on a dock
    icon against 9963 on natively rendered clock text and 0 on empty bar. An
    icon rendered at 1x and stretched would have scored near zero.
  - Deliberate: Qt's scale rounding is left at `PassThrough`, so fractional
    ratios reach the bar and the text renderer switches to a distance field
    rather than hinting onto a grid that does not line up. Rounding to whole
    numbers would be sharper but would size the bar differently from the GTK
    applications next to it.
- System dark mode. `config/gtk-3.0/` and `config/gtk-4.0/` settings, a
  `scripts/.xprofile` that `.xinitrc` and any display manager both source, and
  the portal `color-scheme` keys set by `install.sh`.
  - Passed: the gsettings keys verified applying in a container with a live
    session bus; the app dock proven still resolving real icons through a
    running `xdg-desktop-portal-gtk`.
  - Deliberate: the icon theme stays `Papirus`, not `Papirus-Dark`.
    `Papirus-Dark` ships zero application icons and inherits `breeze-dark`
    rather than `Papirus`, so selecting it empties the dock and the tray.
    Measured: 50828 app icons against 0.
- Test suite, `tests/`: one script per contract, a `make check-<name>` target
  each, stubs on `PATH` instead of mocks, exit 77 for "could not run" so a
  machine without Quickshell can still run the rest.
  Seven tests: the Theme token contract and the black-bar invariants; the tray;
  the layout and sharpness rules from the resolution work; the twelve-key
  record, asserted against SPEC.md on both the writer's side and the bar's;
  `quickshell-launch.sh` run for real against stubs, which is where the
  `Xft.dpi` guards are now pinned down; `dwm-quickshell-state` run for real,
  covering the record it builds, that an event changing nothing emits nothing,
  and that `focus` and `switch` refuse an argument before it reaches `wmctrl`;
  and the bar itself under Xvfb at four widths and three device pixel ratios.
  - Passed in an Arch container: all seven, with `make lint` still at zero
    findings now that it covers `tests/` too. The Xvfb test measured the bar
    window at 32 physical pixels at 1024x600, 1366x768, 1920x1080 and
    3440x1440, 48 at `QT_FONT_DPI=144` and 64 at 192.
  - A grep-based suite is worth nothing if it cannot fail, so fifteen negative
    controls were run against it - a deleted Theme token, a colour literal
    outside Theme, a Wayland import, the dock ceiling removed, a hand-picked
    status width reintroduced, a `renderType` pinned outside `UiText`, the
    layer texture unscaled, a minimum on only one side group, a record key
    renamed, two keys swapped, duplicate suppression deleted, the tray host on
    every monitor, and three more. All fifteen were caught.
  - It found one real defect, now fixed: `focus_window`'s argument check was
    `0x[0-9a-fA-F]* | [0-9]*`, where the second pattern matches the whole of
    anything beginning with a digit, so `0xzz; id` and similar reached `wmctrl`
    unexamined. SPEC.md already claimed the stricter behaviour. Not an
    injection - the value is passed as one quoted argument - but it was not
    what the document said.
  - Not passed, because it cannot be yet: CI. The new `tests` job has never
    run, for the same reason as every other job here.
- Build and lint tooling. `config.mk` widened to `-Wextra` with three
  documented suppressions; `tools/qml-lint.sh`; the three CI jobs.
  - Passed: a negative control, an unused variable injected into `util.c`, was
    correctly rejected by the `-Werror` build.

## Completed

- Decided: `install.sh` does not install a display manager. It keeps detecting
  an enabled one and reporting it, and otherwise points at `startx`. Recorded
  in `SPEC.md`; no code change was needed.
- Decided: `config.h` stays tracked and comes out of `.gitignore`. The entry
  was dead, since tracking wins over an ignore rule, and it was the thing that
  made `git pull` conflict on a machine with local edits. `git check-ignore
  --no-index config.h` and `git ls-files config.h` now agree.

- Decided: the seven Phase 4 fixes ship on one branch rather than seven. They
  are separate logical changes and are separate commits, but they came from a
  single report about a single install, and splitting them across branches
  would order them artificially while two of them touch the same file.

The bar swap has cleared its automated gate and the part of its manual gate
that a first install exercises. No task has cleared the whole of both.
