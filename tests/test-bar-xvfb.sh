#!/bin/sh
# The bar actually running: dwm under Xvfb with the real Quickshell config,
# across the resolutions and device pixel ratios the layout and sharpness rules
# exist for. Exits 77 when Quickshell or Xvfb is absent, which the Makefile
# treats as a skip rather than a failure.
set -eu

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "$0")/.." && pwd
)

for command_name in Xvfb quickshell xprop xwininfo xsetroot xdotool xterm magick pgrep; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		printf 'SKIP: %s is unavailable\n' "$command_name"
		exit 77
	fi
done
[ -x "$repo/dwm" ] || {
	printf 'SKIP: dwm is not built\n'
	exit 77
}

work=$(mktemp -d)
display=":$((($$ % 400) + 500))"
xvfb_pid=
dwm_pid=

cleanup() {
	set +e
	[ -z "$dwm_pid" ] || kill "$dwm_pid" 2>/dev/null
	pkill -f 'quickshell --path' 2>/dev/null
	[ -z "$xvfb_pid" ] || kill "$xvfb_pid" 2>/dev/null
	rm -rf "$work"
}
trap cleanup EXIT HUP INT TERM

home=$work/home
mkdir -p "$home/.config" "$home/.local/bin"
cp -a "$repo/config/quickshell" "$home/.config/quickshell"
cp "$repo/scripts/dwm-quickshell-state" "$repo/scripts/quickshell-launch.sh" \
	"$home/.local/bin/"
chmod +x "$home/.local/bin/"*

# Long enough to collide with the centre clock if the left group stops yielding.
long_title='nvim  ~/src/dwm/config/quickshell/panel/DwmPanel.qml  [+]  3 of 22'
status_line='CPU 12%  |  MEM 4.1G  |  1.2 GHz'

# $1 width, $2 height, $3 expected bar height in physical pixels, $4.. extra env
render() {
	width=$1
	height=$2
	expected=$3
	shift 3

	Xvfb "$display" -screen 0 "${width}x${height}x24" -nolisten tcp \
		+extension GLX +render >"$work/xvfb.log" 2>&1 &
	xvfb_pid=$!

	waited=0
	while [ "$waited" -lt 100 ]; do
		DISPLAY=$display xprop -root >/dev/null 2>&1 && break
		waited=$((waited + 1))
		sleep 0.05
	done
	DISPLAY=$display xprop -root >/dev/null

	env DISPLAY="$display" HOME="$home" PATH="$home/.local/bin:$PATH" \
		QT_QPA_PLATFORMTHEME=gnome LIBGL_ALWAYS_SOFTWARE=1 "$@" \
		"$repo/dwm" >"$work/dwm.log" 2>&1 &
	dwm_pid=$!

	# Quickshell takes noticeably longer on a software GL stack than a real one.
	waited=0
	while [ "$waited" -lt 300 ]; do
		pgrep -f 'quickshell --path' >/dev/null 2>&1 && break
		waited=$((waited + 1))
		sleep 0.1
	done
	pgrep -f 'quickshell --path' >/dev/null || {
		printf 'The bar did not start at %sx%s.\n' "$width" "$height" >&2
		cat "$work/dwm.log" >&2
		return 1
	}

	DISPLAY=$display xsetroot -solid '#000000'
	DISPLAY=$display xterm -T "$long_title" -e sleep 300 >/dev/null 2>&1 &
	sleep 2
	DISPLAY=$display xsetroot -name "$status_line"
	sleep 3
	# Keep the pointer off the bar so nothing is caught in a hover state.
	DISPLAY=$display xdotool mousemove $((width / 2)) $((height - 30))
	sleep 1

	# Ask the server rather than scanning pixels: rows cannot tell the bottom of
	# the bar from the top of the window docked under it.
	geometry=$(DISPLAY=$display xwininfo -root -tree |
		awk '/[Qq]uickshell/ { for (i = 1; i <= NF; i++) if ($i ~ /^[0-9]+x[0-9]+\+/) { print $i; exit } }')
	[ -n "$geometry" ] || {
		printf 'No bar window at %sx%s.\n' "$width" "$height" >&2
		DISPLAY=$display xwininfo -root -tree >&2
		return 1
	}
	measured=${geometry%%+*}
	measured=${measured#*x}
	[ "$measured" -eq "$expected" ] || {
		printf 'Bar is %s physical pixels tall at %sx%s, expected %s.\n' \
			"$measured" "$width" "$height" "$expected" >&2
		return 1
	}
	[ "${geometry%%x*}" -eq "$width" ]
	[ "${geometry##*+}" -eq 0 ]

	# A QML error leaves a window present and empty, which every check short of
	# the pixels calls a success. Crop to the bar so nothing underneath supplies
	# the ink.
	DISPLAY=$display magick import -window root \
		-crop "${width}x${measured}+0+0" "$work/bar.png"
	ink=$(magick "$work/bar.png" -format '%[fx:mean*10000]' info:)
	[ "${ink%%.*}" -gt 0 ] || {
		printf 'The bar window is empty at %sx%s.\n' "$width" "$height" >&2
		return 1
	}

	# QML failures only: a container has no dunst, picom or session bus, so
	# autostart and the DBus services fail here as a matter of course.
	if grep -Eq 'QML [Ee]rror|Error compiling|Failed to load' "$work/dwm.log"; then
		printf 'The bar reported a QML error at %sx%s.\n' "$width" "$height" >&2
		grep -E 'QML [Ee]rror|Error compiling|Failed to load' "$work/dwm.log" >&2
		return 1
	fi
	grep -Fq 'Configuration Loaded' "$work/dwm.log" || {
		printf 'The bar never finished loading at %sx%s.\n' "$width" "$height" >&2
		cat "$work/dwm.log" >&2
		return 1
	}

	kill "$dwm_pid" 2>/dev/null || true
	pkill -f 'quickshell --path' 2>/dev/null || true
	sleep 1
	kill "$xvfb_pid" 2>/dev/null || true
	wait "$xvfb_pid" 2>/dev/null || true
	dwm_pid=
	xvfb_pid=
	printf '  %sx%s: bar %s physical pixels, rendering\n' \
		"$width" "$height" "$measured"
}

# panelHeight is 40 logical pixels, so at a ratio of 1 the bar is 40 physical.
render 1024 600 40
render 1366 768 40
render 1920 1080 40
render 2560 1440 40
render 3440 1440 40

# QT_FONT_DPI is the only knob measured to move Qt's device pixel ratio on
# Xorg. 144 gives the fractional 1.5 that core/UiText.qml's renderer switch
# exists for.
render 1920 1080 60 QT_FONT_DPI=144
render 1920 1080 80 QT_FONT_DPI=192

printf 'Bar renders under Xvfb: PASS\n'
