#!/bin/sh
# powermenu.sh, run for real against stubbed system tools. The defect this was
# written for: logout passed "$XDG_SESSION_ID" to loginctl unconditionally, and
# a display manager does not reliably export that variable into the session, so
# the usual case was `loginctl terminate-session ""` failing under set -e with
# no terminal attached to report it. Every entry looked identical to a menu that
# simply did nothing.
#
# The /sys/power/state gating is not covered here. It reads an absolute kernel
# path, and parameterising that purely so a test could redirect it would put a
# test hook in the menu for no gain at runtime; containers mask the file
# outright, so the uncovered branch is the one that offers every entry.
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
mkdir -p "$bin"

# Records the menu it was handed and returns the scripted choice, so the test
# can assert on both. `rofi -e` is the menu's only way to reach a user, so it is
# recorded rather than swallowed.
cat >"$bin/rofi" <<'SH'
#!/bin/sh
if [ "${1:-}" = "-e" ]; then
	printf 'ROFI-ERROR %s\n' "$2" >>"$CALLS"
	exit 0
fi
cat >"$MENU"
printf '%s\n' "${CHOICE:-}"
SH

cat >"$bin/systemctl" <<'SH'
#!/bin/sh
printf 'systemctl %s\n' "$*" >>"$CALLS"
[ "${FAIL_SYSTEMCTL:-}" = "${1:-}" ] && exit 1
exit 0
SH

# Mirrors the real shapes: terminate-session fails on an empty id, and the
# Display property is typed (so), so --value prints the session id and an
# object path separated by whitespace.
cat >"$bin/loginctl" <<'SH'
#!/bin/sh
printf 'loginctl %s\n' "$*" >>"$CALLS"
case "$*" in
*"--property Display show-user"*)
	[ -z "${FAKE_DISPLAY:-}" ] || printf '%s\n' "$FAKE_DISPLAY"
	;;
*terminate-session*)
	[ -n "${2:-}" ] || exit 1
	;;
esac
exit 0
SH

cat >"$bin/pkill" <<'SH'
#!/bin/sh
printf 'pkill %s\n' "$*" >>"$CALLS"
exit "${PKILL_RC:-0}"
SH

# Not stubs: the menu genuinely uses these.
for passthrough in awk cat id printf; do
	printf '#!/bin/sh\nexec /usr/bin/%s "$@"\n' "$passthrough" >"$bin/$passthrough"
done

chmod +x "$bin"/*

# $1 is the entry the stubbed rofi returns; anything after it goes into the
# menu's environment.
run_menu() {
	: >"$work/calls"
	: >"$work/menu"
	choice=$1
	shift
	# An absolute interpreter, because PATH holds only the stub directory and
	# the menu ships mode 644 - the install target is what makes it executable,
	# and DwmPanel runs it through `sh -c` for the same reason.
	env -i PATH="$bin" HOME="$work" \
		CALLS="$work/calls" MENU="$work/menu" CHOICE="$choice" "$@" \
		/bin/sh "$repo/config/rofi/powermenu.sh" >"$work/out" 2>"$work/err" || {
		printf 'powermenu exited %s for choice "%s"\n' "$?" "$choice" >&2
		exit 1
	}
}

called() {
	grep -Fqx "$1" "$work/calls" || {
		printf 'Expected call "%s", got:\n%s\n' "$1" "$(cat "$work/calls")" >&2
		exit 1
	}
}

not_called() {
	grep -Fq "$1" "$work/calls" && {
		printf 'Did not expect "%s" among:\n%s\n' "$1" "$(cat "$work/calls")" >&2
		exit 1
	}
	return 0
}

# Every entry reaches its action. These are the four that need no session
# lookup.
run_menu '󰤄  suspend'
called 'systemctl suspend'
run_menu '󰒲  hibernate'
called 'systemctl hibernate'
run_menu '󰜉  reboot'
called 'systemctl reboot'
run_menu '󰐥  shutdown'
called 'systemctl poweroff'

# Logout with the variable set uses it directly and asks logind nothing.
run_menu '󰍃  logout' XDG_SESSION_ID=7
called 'loginctl terminate-session 7'
not_called 'show-user'

# The reported defect: no XDG_SESSION_ID. The id has to come from logind, and
# only the first field of the (so) pair is the id.
run_menu '󰍃  logout' FAKE_DISPLAY='3 /org/freedesktop/login1/session/_33'
called 'loginctl terminate-session 3'
not_called 'pkill'

# Nothing knows a session - the startx case - so ending dwm ends the session.
run_menu '󰍃  logout'
called 'pkill -x dwm'

# With no session and no dwm there is nothing left to try, and the one thing
# the menu must still do is say so.
run_menu '󰍃  logout' PKILL_RC=1
grep -Fq 'ROFI-ERROR' "$work/calls" || {
	printf 'A failed logout reported nothing to the user.\n' >&2
	exit 1
}

# A failing action is reported rather than swallowed.
run_menu '󰜉  reboot' FAIL_SYSTEMCTL=reboot
called 'ROFI-ERROR powermenu: reboot failed'

# Dismissing the menu is not an error and must not act.
run_menu ''
[ ! -s "$work/calls" ] || {
	printf 'Dismissing the menu acted anyway:\n%s\n' "$(cat "$work/calls")" >&2
	exit 1
}

# Matching is on the whole line, so the glyph and its spacing are not load
# bearing; an entry that matches nothing is reported rather than ignored.
run_menu 'logout'
called 'pkill -x dwm'
run_menu 'something else'
called 'ROFI-ERROR powermenu: unrecognised choice: something else'

printf 'test-powermenu: all assertions passed\n'
