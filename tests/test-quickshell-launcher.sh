#!/bin/sh
# quickshell-launch.sh, run for real against stubbed tools. The interesting part
# is the Xft.dpi translation: Qt on Xorg reports a flat 96 DPI and ignores
# Xft.dpi, so getting QT_FONT_DPI wrong leaves the bar at 1x on a 4K panel while
# everything around it scales.
#
# xrdb is stubbed rather than used: under Xvfb, `xrdb -query` reads back nothing
# even from a RESOURCE_MANAGER xprop displays correctly, so a test built on the
# real tool would pass against an empty database. The live read is a
# hardware-validation item; see TASKS.md.
#
# PATH holds the stub directory and nothing else, so an installed tool cannot
# stand in for a stub.
set -eu

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "$0")/.." && pwd
)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM

bin=$work/bin
home=$work/home
mkdir -p "$bin" "$home/.config/quickshell"
cp -a "$repo/config/quickshell/." "$home/.config/quickshell/"

# Stands in for the bar: reports the environment it was handed.
cat >"$bin/quickshell" <<'SH'
#!/bin/sh
printf 'QT_FONT_DPI=%s\n' "${QT_FONT_DPI:-UNSET}"
printf 'QT_SCALE_FACTOR=%s\n' "${QT_SCALE_FACTOR:-UNSET}"
printf 'QT_QPA_PLATFORMTHEME=%s\n' "${QT_QPA_PLATFORMTHEME:-UNSET}"
printf 'STATE_TOOL=%s\n' "$(command -v dwm-quickshell-state || printf UNSET)"
printf 'ARGS=%s\n' "$*"
SH

for stub in xprop wmctrl; do
	printf '#!/bin/sh\nexit 0\n' >"$bin/$stub"
done

# Not stubs: the launcher genuinely uses these, and PATH holds this directory
# and nothing else, so they have to be reachable from here.
for passthrough in awk dirname; do
	printf '#!/bin/sh\nexec /usr/bin/%s "$@"\n' "$passthrough" >"$bin/$passthrough"
done

chmod +x "$bin"/*

# $1 is the Xft.dpi the stubbed xrdb reports, empty for no such resource;
# anything after it goes into the launcher's environment. The stub prints a
# multi-line database because the launcher has to pick its resource out of one.
run_launcher() {
	if [ -n "$1" ]; then
		cat >"$bin/xrdb" <<SH
#!/bin/sh
printf 'Xcursor.theme:\tAdwaita\nXft.dpi:\t$1\nXft.antialias:\t1\n'
SH
	else
		cat >"$bin/xrdb" <<'SH'
#!/bin/sh
printf 'Xcursor.theme:\tAdwaita\nXft.antialias:\t1\n'
SH
	fi
	chmod +x "$bin/xrdb"
	shift

	env -i PATH="$bin" HOME="$home" "$@" \
		"$repo/scripts/quickshell-launch.sh" >"$work/out" 2>"$work/err"
}

expect() {
	grep -Fqx "$1=$2" "$work/out" || {
		printf 'Expected %s=%s, got: %s\n' \
			"$1" "$2" "$(grep "^$1=" "$work/out")" >&2
		exit 1
	}
}

# 2x, the fractional 1.5 a laptop at 150% produces, and both ends of the range.
run_launcher 192
expect QT_FONT_DPI 192
run_launcher 144
expect QT_FONT_DPI 144
run_launcher 97
expect QT_FONT_DPI 97
run_launcher 384
expect QT_FONT_DPI 384

# Below 96 nothing needs scaling; past 384 the value is junk.
for value in 96 95 48 0 385 9999; do
	run_launcher "$value"
	expect QT_FONT_DPI UNSET
done

for value in abc 19.2 -192 192px; do
	run_launcher "$value"
	expect QT_FONT_DPI UNSET
done
run_launcher ''
expect QT_FONT_DPI UNSET

# An explicit setting in .xprofile wins.
run_launcher 192 QT_FONT_DPI=120
expect QT_FONT_DPI 120
run_launcher 192 QT_SCALE_FACTOR=1.5
expect QT_FONT_DPI UNSET
expect QT_SCALE_FACTOR 1.5

# Without a platform theme Qt resolves no icon theme and every tray and
# running-app icon comes up blank. An explicit choice is left alone.
run_launcher ''
grep -Eqx 'QT_QPA_PLATFORMTHEME=(gtk3|gnome)' "$work/out" || {
	printf 'No platform theme was selected.\n' >&2
	exit 1
}
run_launcher '' QT_QPA_PLATFORMTHEME=qt6ct
expect QT_QPA_PLATFORMTHEME qt6ct

# --no-duplicate keeps a second run from stacking another bar.
run_launcher ''
grep -Fq -- '--no-duplicate' "$work/out"
grep -Fq -- "--path $home/.config/quickshell" "$work/out"

# ~/.local/bin goes on PATH: the bar shells out to dwm-quickshell-state by bare
# name, and a display manager's PATH does not include it.
run_launcher ''
expect STATE_TOOL UNSET
mkdir -p "$home/.local/bin"
printf '#!/bin/sh\nexit 0\n' >"$home/.local/bin/dwm-quickshell-state"
chmod +x "$home/.local/bin/dwm-quickshell-state"
run_launcher ''
expect STATE_TOOL "$home/.local/bin/dwm-quickshell-state"

# With no user config, the launcher falls back to the tree it was run from.
mv "$home/.config/quickshell" "$work/stashed-config"
run_launcher ''
grep -Fq -- "--path $repo/scripts/../config/quickshell" "$work/out"
mv "$work/stashed-config" "$home/.config/quickshell"

# No xrdb at all is a normal Xorg setup: the bar comes up unscaled.
rm -f "$bin/xrdb"
env -i PATH="$bin" HOME="$home" \
	"$repo/scripts/quickshell-launch.sh" >"$work/out" 2>"$work/err"
expect QT_FONT_DPI UNSET

# A missing hard dependency is named rather than left to fail inside the bar.
for required in quickshell xprop; do
	mv "$bin/$required" "$work/held"
	if env -i PATH="$bin" HOME="$home" \
		"$repo/scripts/quickshell-launch.sh" >"$work/out" 2>"$work/err"; then
		printf 'Launcher started with no %s installed.\n' "$required" >&2
		exit 1
	fi
	grep -Fq 'ERROR' "$work/err"
	mv "$work/held" "$bin/$required"
done

# wmctrl is optional: the bar still runs, clicks just do nothing.
mv "$bin/wmctrl" "$work/held"
run_launcher ''
grep -Fq 'WARNING' "$work/err"
mv "$work/held" "$bin/wmctrl"

printf 'quickshell-launch.sh environment: PASS\n'
