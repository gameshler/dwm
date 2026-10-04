#!/bin/sh
# The three bar menus actually running: dwm under Xvfb with the real Quickshell
# config, driven exactly as a keybinding drives them. Exits 77 when Quickshell
# or Xvfb is absent, which the Makefile treats as a skip rather than a failure.
#
# This exists because the failure it guards against is silent. A menu that takes
# no keystroke, or whose Enter runs nothing, looks identical to one that is
# simply slow, and neither qmllint nor a screenshot can tell the difference. The
# contract spans four pieces that cannot be checked apart: dwm's rules[] entry,
# the window being a managed type dwm will focus, the IpcHandler targets, and
# the helper scripts the menus exec.
set -eu

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "$0")/.." && pwd
)

for command_name in Xvfb quickshell xprop xwininfo xsetroot xdotool pgrep; do
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
display=":$((($$ % 400) + 900))"
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
ran=$work/ran
mkdir -p "$home/.config" "$home/.local/bin" "$home/.config/bookmarks" \
	"$home/projects/alpha-service" "$home/projects/beta-tool" "$home/projects/gamma"
cp -a "$repo/config/quickshell" "$home/.config/quickshell"
cp "$repo/scripts/dwm-quickshell-state" "$repo/scripts/quickshell-launch.sh" \
	"$home/.local/bin/"

cat >"$home/.config/bookmarks/personal.txt" <<'BOOKMARKS'
# personal
https://youtube.com
Hacker News :: https://news.ycombinator.com
BOOKMARKS

cat >"$home/.config/bookmarks/work.txt" <<'BOOKMARKS'
Arch Wiki :: https://wiki.archlinux.org/title/Arch_Linux
BOOKMARKS

# The menus exec these by bare name through the launcher's PATH. Recording
# stubs, so an assertion can be about what the menu decided rather than about
# the machine rebooting.
for helper in dwm-session-action dwm-repo-open dwm-bookmark-open; do
	cat >"$home/.local/bin/$helper" <<SH
#!/bin/sh
printf '$helper %s\n' "\$*" >>"$ran"
exit 0
SH
done
chmod +x "$home/.local/bin/"*

shell_path=$home/.config/quickshell/shell.qml
failures=0

Xvfb "$display" -screen 0 1920x1080x24 -nolisten tcp \
	+extension GLX +render >"$work/xvfb.log" 2>&1 &
xvfb_pid=$!

waited=0
until DISPLAY=$display xprop -root >/dev/null 2>&1; do
	waited=$((waited + 1))
	[ "$waited" -lt 100 ] || {
		printf 'Xvfb did not start.\n' >&2
		exit 1
	}
	sleep 0.1
done

export DISPLAY="$display" HOME="$home"
export PATH="$home/.local/bin:$PATH"

"$repo/dwm" >"$work/dwm.log" 2>&1 &
dwm_pid=$!

waited=0
until pgrep -f 'quickshell --path' >/dev/null 2>&1; do
	waited=$((waited + 1))
	[ "$waited" -lt 400 ] || {
		printf 'The bar never started.\n' >&2
		exit 1
	}
	sleep 0.1
done
sleep 5

ipc() {
	quickshell ipc --path "$shell_path" "$@" 2>>"$work/ipc.log"
}

menu_window() {
	xdotool search --name '^dwm-menu$' 2>/dev/null | head -1
}

menu_mapped() {
	window=$(menu_window)
	[ -n "$window" ] || return 1
	xwininfo -id "$window" 2>/dev/null | grep -q 'Map State: IsViewable'
}

fail() {
	printf '%s\n' "$1" >&2
	failures=$((failures + 1))
}

# Every target a keybinding in config.h names has to be registered, or the key
# does nothing at all.
targets=$(ipc show | awk '$1 == "target" { print $2 }' | sort | tr '\n' ' ')
for target in bookmarks power repos; do
	case " $targets " in
	*" $target "*) ;;
	*) fail "No IPC target named $target. Registered: $targets" ;;
	esac
done

open_menu() {
	: >"$ran"
	ipc call "$1" open >/dev/null
	waited=0
	until menu_mapped; do
		waited=$((waited + 1))
		[ "$waited" -lt 100 ] || {
			fail "The $1 menu never appeared."
			return 1
		}
		sleep 0.1
	done
}

expect_ran() {
	if ! grep -qF -- "$1" "$ran" 2>/dev/null; then
		fail "Expected the menu to run: $1
Instead it ran: $(cat "$ran" 2>/dev/null)"
	fi
}

# dwm has to focus the menu, or no keystroke reaches it. This is the whole
# reason MenuWindow is a FloatingWindow: a Quickshell panel or popup is a
# dock-type window on X11 and dwm never focuses one.
open_menu power || true
if [ "$(xdotool getwindowfocus 2>/dev/null)" != "$(menu_window)" ]; then
	fail 'dwm did not focus the menu, so it cannot take a keystroke.'
fi

# Typing filters, and Enter runs the entry that survived.
xdotool type --delay 40 'res'
sleep 1
xdotool key Return
sleep 2
expect_ran 'dwm-session-action reboot'

# The arrow keys move the selection, so the menu is usable without typing.
open_menu power || true
xdotool key Down Down
sleep 1
xdotool key Return
sleep 2
expect_ran 'dwm-session-action hibernate'

# Escape dismisses without running anything.
open_menu power || true
xdotool key Escape
sleep 1
if menu_mapped; then
	fail 'Escape did not close the menu.'
fi
if [ -s "$ran" ]; then
	fail "Escape ran something: $(cat "$ran")"
fi

# A project whose name contains a space still arrives as one argument, which is
# why the list is built with find rather than ls.
open_menu repos || true
xdotool type --delay 40 'beta'
sleep 1
xdotool key Return
sleep 2
expect_ran "dwm-repo-open $home/projects/beta-tool"

# The file a bookmark came from picks the browser, so the tag has to survive
# the trip through the menu.
open_menu bookmarks || true
xdotool type --delay 40 'arch'
sleep 1
xdotool key Return
sleep 2
expect_ran 'dwm-bookmark-open work https://wiki.archlinux.org/title/Arch_Linux'

if [ "$failures" -ne 0 ]; then
	printf 'test-menus-xvfb: %s assertion(s) failed\n' "$failures" >&2
	exit 1
fi

printf 'Bar menus under Xvfb: PASS\n'
