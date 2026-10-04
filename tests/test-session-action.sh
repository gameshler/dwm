#!/bin/sh
# dwm-session-action, run for real against stubbed system tools. The defect this
# was written for: logout passed "$XDG_SESSION_ID" to loginctl unconditionally,
# and a display manager does not reliably export that variable into the session,
# so the usual case was `loginctl terminate-session ""` failing under set -e
# with nothing attached to report it. Every entry looked identical to a menu
# that simply did nothing.
#
# The bar reads this script's stderr and puts it on screen, so the assertions
# below are as much about what it says as about what it ran.
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

cat >"$bin/systemctl" <<'SH'
#!/bin/sh
printf 'systemctl %s\n' "$*" >>"$CALLS"
[ "${FAIL_SYSTEMCTL:-}" = "${1:-}" ] && exit 1
exit 0
SH

# Mirrors the real shapes: terminate-session fails on an empty id, and the
# Display property is typed (so), so --value prints the session id and an object
# path separated by whitespace.
cat >"$bin/loginctl" <<'SH'
#!/bin/sh
printf 'loginctl %s\n' "$*" >>"$CALLS"
case "$*" in
*"--property Display show-user"*)
	[ -z "${FAKE_DISPLAY:-}" ] || printf '%s\n' "$FAKE_DISPLAY"
	;;
*terminate-session*)
	[ -n "${2:-}" ] || exit 1
	[ "${FAIL_TERMINATE:-}" != "yes" ] || exit 1
	;;
esac
exit 0
SH

cat >"$bin/pkill" <<'SH'
#!/bin/sh
printf 'pkill %s\n' "$*" >>"$CALLS"
[ "${DWM_RUNNING:-yes}" = "yes" ] || exit 1
exit 0
SH

cat >"$bin/id" <<'SH'
#!/bin/sh
printf 'tester\n'
SH

# The script parses logind's output with awk, and PATH holds only stubs.
printf '#!/bin/sh\nexec %s "$@"\n' "$(command -v awk)" >"$bin/awk"

chmod +x "$bin"/*

failures=0

# An absolute interpreter: PATH holds only stubs, so `sh` would not resolve, and
# the script ships mode 644 until `make install` marks it executable.
run() {
	action=$1
	shift
	CALLS=$work/calls
	: >"$CALLS"
	: >"$work/err"
	set +e
	env -i PATH="$bin" CALLS="$CALLS" HOME="$work" "$@" \
		/bin/sh "$repo/scripts/dwm-session-action" "$action" \
		>"$work/out" 2>"$work/err"
	status=$?
	set -e
}

expect_call() {
	if ! grep -qF -- "$1" "$work/calls"; then
		printf 'Expected a call matching: %s\n' "$1" >&2
		printf 'Calls were:\n' >&2
		sed 's/^/  /' "$work/calls" >&2
		failures=$((failures + 1))
	fi
}

expect_status() {
	if [ "$status" -ne "$1" ]; then
		printf 'Expected exit %s, got %s. stderr:\n' "$1" "$status" >&2
		sed 's/^/  /' "$work/err" >&2
		failures=$((failures + 1))
	fi
}

expect_stderr() {
	if ! grep -qiF -- "$1" "$work/err"; then
		printf 'Expected stderr to mention: %s\n' "$1" >&2
		printf 'stderr was:\n' >&2
		sed 's/^/  /' "$work/err" >&2
		failures=$((failures + 1))
	fi
}

# The reported defect: no XDG_SESSION_ID. The id has to come from logind, and
# only the first field of the (so) pair is the session id.
run logout FAKE_DISPLAY="7 /org/freedesktop/login1/session/_37"
expect_status 0
expect_call "loginctl terminate-session 7"

# XDG_SESSION_ID present is the easy path and must not regress.
run logout XDG_SESSION_ID=3
expect_status 0
expect_call "loginctl terminate-session 3"

# No session at all: ending dwm ends the X session, which is what logout means
# under startx.
run logout
expect_status 0
expect_call "pkill -x dwm"

# Nothing left to try is reported rather than swallowed, because the bar has
# nowhere else to learn it from.
run logout DWM_RUNNING=no
expect_status 1
expect_stderr "could not log out"

for pair in "suspend suspend" "hibernate hibernate" "reboot reboot" "poweroff poweroff"; do
	action=${pair% *}
	expected=${pair#* }
	run "$action"
	expect_status 0
	expect_call "systemctl $expected"
done

# A failing action is reported, not swallowed. Hibernate carries the reason it
# usually fails, since the kernel gate cannot see swap size or resume=.
run hibernate FAIL_SYSTEMCTL=hibernate
expect_status 1
expect_stderr "resume="

run poweroff FAIL_SYSTEMCTL=poweroff
expect_status 1
expect_stderr "shutdown failed"

# An unknown action is a usage error, not a silent no-op.
run frobnicate
expect_status 2
expect_stderr "usage:"

if [ "$failures" -ne 0 ]; then
	printf 'test-session-action: %s assertion(s) failed\n' "$failures" >&2
	exit 1
fi

printf 'test-session-action: all assertions passed\n'
