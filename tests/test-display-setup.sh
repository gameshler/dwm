#!/bin/sh
# display-setup.sh, run for real against a stubbed xrandr. Two defects are
# reproduced here.
#
# The refresh rate was read by grepping the whole query for the resolution
# string, which also matched the output's own `connected` header - that line
# carries the panel's physical size, so a 2560x1440 monitor yielded "597", the
# width in millimetres. xrandr rejects an unavailable rate and refuses the whole
# command, so no output was ever configured.
#
# The arrangement followed connector-name order, which has nothing to do with
# where the monitors sit, so a panel on the left could only be reached by moving
# the pointer right.
#
# PATH holds the stub directory and nothing else, so an installed xrandr cannot
# stand in for the stub.
set -eu

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "$0")/.." && pwd
)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM

bin=$work/bin
home=$work/home
mkdir -p "$bin" "$home/.config/dwm"

# A 1440p and a 1080p panel plus a dead connector, in the real shape: the
# header line carries the current geometry and the physical size in millimetres,
# and rates are suffixed * for current and + for preferred.
cat >"$bin/xrandr" <<'SH'
#!/bin/sh
if [ "${1:-}" = "--query" ]; then
	cat <<'Q'
Screen 0: minimum 320 x 200, current 3840 x 1440, maximum 16384 x 16384
DP-2 connected primary 2560x1440+0+0 (normal left inverted right x axis y axis) 597mm x 336mm
   2560x1440    143.86*+ 120.00   59.95
   1920x1080     60.00    59.94
HDMI-1 connected 1920x1080+2560+0 (normal left inverted right x axis y axis) 527mm x 296mm
   1920x1080     75.00*+  60.00    59.94
   1280x720      60.00
DP-3 disconnected (normal left inverted right x axis y axis)
Q
	exit 0
fi
printf 'APPLIED %s\n' "$*"
SH

for passthrough in awk cat grep cut tr; do
	printf '#!/bin/sh\nexec /usr/bin/%s "$@"\n' "$passthrough" >"$bin/$passthrough"
done

chmod +x "$bin"/*

# $1 is the monitors.conf body, or the literal NONE for no file at all.
run_setup() {
	if [ "$1" = NONE ]; then
		rm -f "$home/.config/dwm/monitors.conf"
	else
		printf '%s' "$1" >"$home/.config/dwm/monitors.conf"
	fi
	env -i PATH="$bin" HOME="$home" \
		/bin/bash "$repo/scripts/display-setup.sh" >"$work/out" 2>"$work/err"
}

expect_applied() {
	grep -Fqx "APPLIED $1" "$work/out" || {
		printf 'Expected:\n  APPLIED %s\nGot:\n  %s\n' \
			"$1" "$(cat "$work/out")" >&2
		exit 1
	}
}

dp2='--output DP-2 --primary --mode 2560x1440 --rate 143.86'
hdmi_right='--output HDMI-1 --mode 1920x1080 --rate 75.00 --right-of DP-2'
hdmi='--output HDMI-1 --primary --mode 1920x1080 --rate 75.00'
dp2_right='--output DP-2 --mode 2560x1440 --rate 143.86 --right-of HDMI-1'

# No layout file: connector-name order, as before. The rates are the ones on the
# mode lines - 143.86 and 75.00. Before the fix these were 597 and 2560, read
# off the physical-size and geometry fields of the header.
run_setup NONE
expect_applied "$dp2 $hdmi_right"

# The 1080p panel is physically on the left, so it is primary and DP-2 sits to
# its right. This is the case that was impossible before.
run_setup '# desk, left to right
HDMI-1
DP-2
'
expect_applied "$hdmi $dp2_right"

# The other way round.
run_setup 'DP-2
HDMI-1
'
expect_applied "$dp2 $hdmi_right"

# A connected output the file omits is appended on the right rather than left
# dark.
run_setup 'HDMI-1
'
expect_applied "$hdmi $dp2_right"

# Comments, blank lines, surrounding whitespace, a duplicate and a name that is
# not connected are all tolerated without changing the result.
run_setup '
# a comment
DP-9
  HDMI-1
HDMI-1

DP-2 # trailing comment
'
expect_applied "$hdmi $dp2_right"

# A file naming nothing connected falls back to connector order rather than
# configuring no displays at all.
run_setup 'DP-9
VGA-1
'
expect_applied "$dp2 $hdmi_right"

printf 'test-display-setup: all assertions passed\n'
