#!/bin/sh
# The record format, asserted on every side of it. AGENTS.md: "The bar and
# dwm-quickshell-state share a line-oriented record format. A change to one is a
# change to both." Nothing enforced that, and the failure is quiet. SPEC.md is
# the source of truth, so the test fails if the writer drifts from the document
# rather than only if the two halves of the code drift from each other.
set -eu

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "$0")/.." && pwd
)

writer=$repo/scripts/dwm-quickshell-state
reader=$repo/config/quickshell/state/DwmState.qml
spec=$repo/SPEC.md

# The keys SPEC.md documents, in the order it documents them.
spec_keys=$(awk '
	/twelve keys, in this order:/ { want = 1; next }
	want && /^```/ { fences++; if (fences == 2) exit; next }
	want && fences == 1 && /^[a-z_]+=/ { sub(/=.*/, "", $0); printf "%s ", $0 }
' "$spec")
[ "$(printf '%s' "$spec_keys" | wc -w)" -eq 12 ] || {
	printf 'SPEC.md no longer documents twelve record keys: %s\n' "$spec_keys" >&2
	exit 1
}

# The keys the writer emits, in order. The record is one quoted here-string, so
# this reads the assignment rather than the script.
writer_keys=$(awk '
	/^[[:space:]]*record="/ { inrecord = 1 }
	inrecord {
		closing = ($0 ~ /"[[:space:]]*$/)
		line = $0
		sub(/^[[:space:]]*record="/, "", line)
		sub(/=.*$/, "", line)
		printf "%s ", line
		if (closing) exit
	}
' "$writer")

[ "$writer_keys" = "$spec_keys" ] || {
	printf 'Record keys drifted from SPEC.md.\n  writer: %s\n  spec:   %s\n' \
		"$writer_keys" "$spec_keys" >&2
	exit 1
}

# The writer spies exactly the root properties it parses: the two drifting apart
# means an update nothing reports or an event nothing acts on.
for property in \
	_DWM_MONITOR_DESKTOPS _DWM_SELECTED_MONITOR _DWM_FULLSCREEN_MONITORS \
	_NET_CURRENT_DESKTOP _NET_NUMBER_OF_DESKTOPS _NET_DESKTOP_NAMES \
	_NET_ACTIVE_WINDOW _NET_CLIENT_LIST WM_NAME; do
	grep -Fq "$property" "$writer" || {
		printf 'Root property is no longer watched: %s\n' "$property" >&2
		exit 1
	}
done

# One batched read and one long-lived spy, both over the same named set.
# shellcheck disable=SC2016 # matching the script's text, not expanding it
grep -Fq 'xprop -root $ROOT_PROPERTIES' "$writer"
# shellcheck disable=SC2016
grep -Fq 'xprop -root -spy $ROOT_PROPERTIES' "$writer"

# Every key that carries a value the bar renders. count and active_window are
# bookkeeping derived from other keys, listed as deliberate exclusions.
for key in current monitor_desktops focused_monitor names occupied \
	fullscreen_monitors apps title class status; do
	grep -Fq "key === \"$key\"" "$reader" || {
		printf 'DwmState.qml ignores record key: %s\n' "$key" >&2
		exit 1
	}
done

# Records are separated by a blank line.
grep -Fq "printf '%s\\n\\n' \"\$record\"" "$writer"

# An untouched desktop emits nothing: several properties change together on one
# user action, and a restarted title spy re-reports an unchanged title.
# shellcheck disable=SC2016
grep -Fq '[ "$record" != "$last_record" ] || return 0' "$writer"

# xprop -spy prints every current value before reporting a single change; those
# lines are not events.
grep -Fq 'skip=$#' "$writer"

# Anything that is not a hex window id or a decimal tag index is refused before
# wmctrl runs.
grep -Fq 'usage: %s switch <zero-based-workspace>' "$writer"
grep -Fq 'usage: %s focus <window-id>' "$writer"

printf 'dwm-quickshell-state record protocol: PASS\n'
