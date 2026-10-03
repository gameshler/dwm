# Project tasks

Current phase: Phase 3, release readiness. See `ROADMAP.md`.

## Current phase

- [ ] Run the manual hardware validation Phases 1 and 2 are both waiting on.
  - Scope: install this branch on the Arch machine and exercise the bar.
  - Acceptance criteria: every module renders; clicking a tag switches tags;
    clicking an app icon focuses that window on the current tag and across
    tags; `kill -9` on `dwm-quickshell-state` results in the bar restarting it;
    an untouched desktop emits zero records and shows no measurable CPU.
  - Added by the black redesign, all still unproven on hardware: the bar reads
    as black against the real wallpaper rather than as a grey stripe; the app
    dock still resolves real icons now that the icon theme is set through the
    portal; GTK applications come up dark; Qt applications come up dark; the
    update pill appears only when updates are pending and its click opens a
    terminal; a machine with no battery and no bluetooth draws no doubled
    separator.
  - Added by the design fixes: the dock icons draw greyscale and return to full
    colour under the pointer, on the real GPU rather than llvmpipe; the window
    title and the tooltips render in Inter, not in FiraCode.
  - Added by the resolution work, and the one leg no container could cover:
    put `Xft.dpi: 192` in `~/.Xresources`, log in, and check the bar comes up
    at twice the size along with dwm's own font and rofi. `xrdb -query` reads
    back nothing under Xvfb, in an emulated amd64 Arch container and in a
    native arm64 Debian one alike, so the `Xft.dpi` to `QT_FONT_DPI`
    translation in `quickshell-launch.sh` is proven only against a stubbed
    `xrdb -query`. The fault was isolated to `xrdb` itself rather than to the
    X server: `xrdb -merge` and `xprop -set` both store nothing because they
    exit without `XSetCloseDownMode(RetainPermanent)`, and a setter that does
    call it leaves a RESOURCE_MANAGER that `xprop` reads back correctly and
    `xrdb -query` still does not see. Also unproven on hardware: that a real
    HiDPI panel reports the device pixel ratio the bar then scales by.
  - Automated validation: none applies. This is the gate automation cannot
    cover.
  - Manual validation: is the task.
  - Dependencies or blockers: none. Everything needed is on the branch.

- [ ] Split the working tree into atomic commits.
  - Scope: six logical changes, currently one tree. The bar swap including the
    polybar deletions; the `dwm.c` focus fix; `install.sh` and its README
    section; the `config.mk` `-Wextra` widening; the CI workflow and
    `tools/qml-lint.sh`; the shell script formatting and shellcheck fixes.
  - Acceptance criteria: each commit builds and lints on its own; no commit
    bundles unrelated changes; Conventional Commits format.
  - Automated validation: `make CC="cc -Werror"` and `make lint` at each
    commit.
  - Manual validation: read the diff of each commit in isolation.
  - Dependencies or blockers: no commit authorization has been given for this
    repo. Blocked until it is.

- [ ] Open the pull request and merge before archsetup PR #21.
  - Scope: one pull request from `gameshler/feat/quickshell-bar-swap`.
  - Acceptance criteria: CI green; merged; archsetup PR #21 merged after, not
    before.
  - Automated validation: all four CI jobs.
  - Manual validation: hardware validation above must be done first.
  - Dependencies or blockers: every task above. Ordering against archsetup
    matters because its dwm tab clones this repo's `main` and its ghostty and
    rofi steps `curl` files from it; merging archsetup first installs
    Quickshell packages onto a polybar config.

## Built, pending manual validation

These are implemented and their automated gates pass. They are not complete,
because the hardware gate in `ROADMAP.md` has not run. Residual risk on all of
them is the same: everything was proven under Xvfb in a container, which is not
the machine this has to work on.

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

No implementation task has cleared both its automated and its manual
validation.
