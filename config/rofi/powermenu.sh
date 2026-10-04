#!/bin/sh
# Power menu, opened by the bar's power pill and by the rofi keybinding in
# config.h.
set -eu

prompt="Power:"

# Both callers start this detached with no terminal attached, so a message on
# stderr goes nowhere a user will ever see - which is why every failure below
# used to look like the menu doing nothing. rofi is present by definition here,
# since the menu itself just ran through it, and `rofi -e` puts text on screen.
# notify-send is not a safe choice: dunst does not depend on libnotify and
# nothing else in the install list pulls it in.
fail() {
	printf 'powermenu: %s\n' "$1" >&2
	rofi -e "powermenu: $1" || true
}

# /sys/power/state lists the sleep states this kernel will accept: "mem" is
# suspend-to-RAM, "disk" is hibernate. Hibernate also needs swap at least the
# size of RAM and a resume= kernel parameter, which only systemd can judge, so
# this gate is necessary rather than sufficient - a machine that passes it can
# still refuse, and fail() reports that when it happens. Offering an entry the
# kernel cannot honour at all is the part worth avoiding.
power_states="$(cat /sys/power/state 2>/dev/null || true)"

supports() {
	# An unreadable or empty /sys/power/state proves nothing - containers mask
	# it entirely - so offer the entry rather than withdrawing one that works
	# today. Only a list that was read and does not name the state hides it.
	[ -n "$power_states" ] || return 0

	case " $power_states " in
	*" $1 "*) return 0 ;;
	*) return 1 ;;
	esac
}

menu() {
	printf '%s\n' "󰍃  logout"
	if supports mem; then
		printf '%s\n' "󰤄  suspend"
	fi
	if supports disk; then
		printf '%s\n' "󰒲  hibernate"
	fi
	printf '%s\n' "󰜉  reboot"
	printf '%s\n' "󰐥  shutdown"
}

do_logout() {
	# pam_systemd sets XDG_SESSION_ID for the login session, but a display
	# manager does not reliably export it into the session's own environment
	# and startx never does, so the previous unconditional
	# `loginctl terminate-session "$XDG_SESSION_ID"` was usually called with an
	# empty argument and failed. Ask logind when the variable is missing: the
	# user object's Display property is the primary graphical session. It is
	# typed (so) - session id and object path - so only the first field is the
	# id.
	sid="${XDG_SESSION_ID:-}"
	if [ -z "$sid" ]; then
		sid="$(loginctl --value --property Display show-user "$(id -un)" 2>/dev/null |
			awk 'NR == 1 { print $1 }' || true)"
	fi

	if [ -n "$sid" ] && loginctl terminate-session "$sid" 2>/dev/null; then
		return 0
	fi

	# Ending dwm ends the X session, which is what logout means here. This is
	# the path that works under startx, where there may be no logind session to
	# terminate at all.
	if pkill -x dwm 2>/dev/null; then
		return 0
	fi

	fail "could not log out: logind reported no session and dwm is not running"
}

# rofi exits non-zero when the menu is dismissed with Escape, which under set -e
# would abort here before the emptiness check below could run.
choice="$(menu | rofi -dmenu -i -p "$prompt" || true)"
[ -n "$choice" ] || exit 0

# Matched on the whole line rather than by stripping the glyph off the front.
# The previous `sed 's/^[^ ]*  //'` depended on the icon being followed by
# exactly two spaces, so any change to the menu text silently stopped matching
# and fell through the case below without doing anything.
case "$choice" in
*logout*) do_logout ;;
*suspend*) systemctl suspend || fail "suspend failed" ;;
*hibernate*) systemctl hibernate || fail "hibernate failed - check swap size and the resume= kernel parameter" ;;
*reboot*) systemctl reboot || fail "reboot failed" ;;
*shutdown*) systemctl poweroff || fail "shutdown failed" ;;
*) fail "unrecognised choice: $choice" ;;
esac
