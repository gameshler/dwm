#!/bin/sh
set -eu

terminal="ghostty"

mkdir -p "$HOME/projects"

# find rather than ls: a directory name with a space or newline still reaches
# rofi as one entry.
configs="$(find "$HOME/projects" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort)"
[ -n "$configs" ] || exit 0
chosen="$(printf '%s\n' "$configs" | rofi -dmenu -p 'Projects:')"
[ -n "$chosen" ] || exit 0
dir="$HOME/projects/$chosen"

pkill -x $terminal 2>/dev/null || true
sleep 0.1

exec $terminal -e tmux new-session -As "$chosen" -c "$dir" "nvim ."
