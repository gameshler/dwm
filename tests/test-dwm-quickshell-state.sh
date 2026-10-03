#!/bin/sh
# dwm-quickshell-state, run for real against a stubbed X session: the record it
# builds, that an event changing nothing produces no record, and that the two
# commands flowing back to dwm refuse an argument wmctrl would act on.
set -eu

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "$0")/.." && pwd
)

state_tool=$repo/scripts/dwm-quickshell-state
work=$(mktemp -d)
watch_pid=

cleanup() {
	[ -z "$watch_pid" ] || kill "$watch_pid" 2>/dev/null || true
	rm -rf "$work"
}
trap cleanup EXIT HUP INT TERM

bin=$work/bin
mkdir -p "$bin"
export STATE_TEST_DIR="$work"

# What xprop -root reports, as a file so a test can change the desktop between
# events. The absent property is spelled the way xprop spells it: "not found."
# reaching the record as a value is a real failure mode.
cat >"$work/root" <<'EOF'
_DWM_MONITOR_DESKTOPS(CARDINAL) = 0, 0, 1920, 1080, 0
_DWM_SELECTED_MONITOR(CARDINAL) = 0
_DWM_FULLSCREEN_MONITORS:  not found.
_NET_CURRENT_DESKTOP(CARDINAL) = 0
_NET_NUMBER_OF_DESKTOPS(CARDINAL) = 9
_NET_DESKTOP_NAMES(UTF8_STRING) = "1", "2", "3", "4", "5", "6", "7", "8", "9"
_NET_ACTIVE_WINDOW(WINDOW): window id # 0x400001
_NET_CLIENT_LIST(WINDOW): window id # 0x400001, 0x400002
WM_NAME(STRING) = "CPU 12%  |  MEM 4.1G"
EOF

# xdotool reports in decimal and the client list carries hex, which is why
# active_window and the apps ids do not look alike.
printf '4194305\n' >"$work/active"

cat >"$bin/xprop" <<'SH'
#!/bin/sh
case ${1:-} in
-root)
	shift
	case "$*" in
	-spy*) exec sh "$STATE_TEST_DIR/spy" ;;
	esac
	cat "$STATE_TEST_DIR/root"
	;;
-id)
	window=$2
	shift 2
	case "$*" in
	*-spy*) exec sleep 300 ;;
	esac
	case $window in
	4194305 | 0x400001)
		case "$*" in
		*_NET_WM_DESKTOP*)
			printf '_NET_WM_DESKTOP(CARDINAL) = 0\n'
			printf 'WM_CLASS(STRING) = "xterm", "XTerm"\n'
			;;
		*)
			printf '_NET_WM_NAME(UTF8_STRING) = "%s"\n' "$(cat "$STATE_TEST_DIR/title")"
			printf 'WM_NAME(STRING) = "xterm"\n'
			printf 'WM_CLASS(STRING) = "xterm", "XTerm"\n'
			;;
		esac
		;;
	0x400002)
		printf '_NET_WM_DESKTOP(CARDINAL) = 2\n'
		printf 'WM_CLASS(STRING) = "Navigator", "Firefox"\n'
		;;
	esac
	;;
esac
SH

cat >"$bin/xdotool" <<'SH'
#!/bin/sh
case ${1:-} in
getactivewindow) cat "$STATE_TEST_DIR/active" ;;
esac
SH

cat >"$bin/wmctrl" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >>"$STATE_TEST_DIR/wmctrl.log"
SH

chmod +x "$bin"/*
printf 'nvim  ~/src/dwm/dwm.c\n' >"$work/title"
PATH=$bin:/usr/bin:/bin
export PATH

# -- the record -------------------------------------------------------------
"$state_tool" state >"$work/record"

[ "$(wc -l <"$work/record")" -eq 12 ] || {
	printf 'Expected a twelve-line record, got %s lines.\n' \
		"$(wc -l <"$work/record")" >&2
	cat "$work/record" >&2
	exit 1
}

expect_line() {
	grep -Fqx "$1" "$work/record" || {
		printf 'Record line missing: %s\n' "$1" >&2
		cat "$work/record" >&2
		exit 1
	}
}

expect_line 'current=0'
# xprop reports "0, 0, 1920, 1080, 0"; the bar splits on the comma.
expect_line 'monitor_desktops=0,0,1920,1080,0'
expect_line 'focused_monitor=0'
expect_line 'count=9'
expect_line 'names=1|2|3|4|5|6|7|8|9'
# One client on tag 0 and one on tag 2.
expect_line 'occupied=0|2'
# Absent property, not the string xprop prints for one.
expect_line 'fullscreen_monitors='
# Deduplicated by class, lower-cased for the icon theme lookup, id:class pairs.
expect_line 'apps=0x400001:xterm|0x400002:firefox'
expect_line 'active_window=4194305'
expect_line 'title=nvim  ~/src/dwm/dwm.c'
expect_line 'class=xterm'
expect_line 'status=CPU 12%  |  MEM 4.1G'

# Nothing focused still produces a usable record.
printf '\n' >"$work/active"
cat >"$work/root" <<'EOF'
_NET_CURRENT_DESKTOP(CARDINAL) = 0
_NET_NUMBER_OF_DESKTOPS(CARDINAL) = 9
_NET_ACTIVE_WINDOW(WINDOW): window id # 0x0
_NET_CLIENT_LIST(WINDOW): window id #
EOF
"$state_tool" state >"$work/record"
expect_line 'title=Desktop'
expect_line 'class=application-x-executable'
expect_line 'apps='
expect_line 'status='
# dwm has not published names yet: fall back to 1..count.
expect_line 'names=1|2|3|4|5|6|7|8|9'

# The record is positional, so a value running onto a second line would shift
# every key after it.
cat >"$work/root" <<'EOF'
_NET_CURRENT_DESKTOP(CARDINAL) = 0
_NET_NUMBER_OF_DESKTOPS(CARDINAL) = 9
WM_NAME(STRING) = "first
second"
EOF
"$state_tool" state >"$work/record"
[ "$(wc -l <"$work/record")" -eq 12 ]

# -- watch: an event that changes nothing emits nothing ---------------------
write_root() {
	cat >"$work/root" <<EOF
_DWM_MONITOR_DESKTOPS(CARDINAL) = 0, 0, 1920, 1080, 0
_DWM_SELECTED_MONITOR(CARDINAL) = 0
_DWM_FULLSCREEN_MONITORS:  not found.
_NET_CURRENT_DESKTOP(CARDINAL) = $1
_NET_NUMBER_OF_DESKTOPS(CARDINAL) = 9
_NET_DESKTOP_NAMES(UTF8_STRING) = "1", "2", "3", "4", "5", "6", "7", "8", "9"
_NET_ACTIVE_WINDOW(WINDOW): window id # 0x400001
_NET_CLIENT_LIST(WINDOW): window id # 0x400001, 0x400002
WM_NAME(STRING) = "CPU 12%  |  MEM 4.1G"
EOF
}
write_root 0
printf '4194305\n' >"$work/active"

# xprop -spy prints every current value before reporting a change, so the first
# nine lines are the priming dump. Then three events that change nothing and
# one that does.
cat >"$work/spy" <<'SH'
i=0
while [ "$i" -lt 9 ]; do
	printf '_NET_CURRENT_DESKTOP(CARDINAL) = 0\n'
	i=$((i + 1))
done
i=0
while [ "$i" -lt 3 ]; do
	printf '_NET_CURRENT_DESKTOP(CARDINAL) = 0\n'
	i=$((i + 1))
	sleep 0.1
done
while [ ! -e "$STATE_TEST_DIR/go" ]; do sleep 0.05; done
printf '_NET_CURRENT_DESKTOP(CARDINAL) = 3\n'
sleep 5
SH

"$state_tool" watch >"$work/stream" 2>"$work/watch.err" &
watch_pid=$!

records() {
	count=$(grep -c '^current=' "$work/stream" 2>/dev/null) || count=0
	printf '%s\n' "$count"
}

waited=0
while [ "$(records)" -lt 1 ] && [ "$waited" -lt 100 ]; do
	waited=$((waited + 1))
	sleep 0.05
done
[ "$(records)" -eq 1 ] || {
	printf 'Watch did not emit its initial record.\n' >&2
	exit 1
}

sleep 1
[ "$(records)" -eq 1 ] || {
	printf 'Events that changed nothing produced %s records.\n' "$(records)" >&2
	cat "$work/stream" >&2
	exit 1
}

write_root 3
: >"$work/go"

waited=0
while [ "$(records)" -lt 2 ] && [ "$waited" -lt 100 ]; do
	waited=$((waited + 1))
	sleep 0.05
done
[ "$(records)" -eq 2 ] || {
	printf 'A real change produced %s records.\n' "$(records)" >&2
	cat "$work/stream" >&2
	exit 1
}
grep -Fqx 'current=3' "$work/stream"

# Records are separated by a blank line.
[ "$(grep -c '^$' "$work/stream")" -ge 2 ]

kill "$watch_pid" 2>/dev/null || true
wait "$watch_pid" 2>/dev/null || true
watch_pid=

# -- the commands flowing back to dwm ---------------------------------------
# Anything that is not a hex window id or a decimal tag index is refused before
# wmctrl is reached.
: >"$work/wmctrl.log"

# Literals on purpose: none of them is ever expanded or executed.
# shellcheck disable=SC2016
for argument in '' abc -1 '3; rm -rf /' '$(id)' 2.5; do
	status=0
	"$state_tool" switch "$argument" >/dev/null 2>&1 || status=$?
	[ "$status" -eq 2 ] || {
		printf 'switch accepted %s (exit %s).\n' "'$argument'" "$status" >&2
		exit 1
	}
done

for argument in '' xyz '0xzz; id' 'window'; do
	status=0
	"$state_tool" focus "$argument" >/dev/null 2>&1 || status=$?
	[ "$status" -eq 2 ] || {
		printf 'focus accepted %s (exit %s).\n' "'$argument'" "$status" >&2
		exit 1
	}
done

[ ! -s "$work/wmctrl.log" ] || {
	printf 'A refused argument still reached wmctrl.\n' >&2
	cat "$work/wmctrl.log" >&2
	exit 1
}

# What they do accept.
"$state_tool" switch 3
"$state_tool" focus 0x400001
"$state_tool" focus 4194305
# -e, because every one of these starts with a dash.
grep -Fqx -e '-s 3' "$work/wmctrl.log"
grep -Fqx -e '-ia 0x400001' "$work/wmctrl.log"
grep -Fqx -e '-ia 4194305' "$work/wmctrl.log"

status=0
"$state_tool" nonsense >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ]

printf 'dwm-quickshell-state behaviour: PASS\n'
