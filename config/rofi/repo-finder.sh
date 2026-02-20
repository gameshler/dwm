#!/bin/sh
set -eu

terminal="ghostty"

configs="$(ls -1d "$HOME"/repos/*/ 2>/dev/null | xargs -n1 basename)"
[ -n "$configs" ] || exit 0
chosen="$(printf '%s\n' $configs | rofi -dmenu -p 'Projects:')"
[ -n "$chosen" ] || exit 0
dir="$HOME/repos/$chosen"

pkill -x $terminal 2>/dev/null || true
sleep 0.1

exec $terminal -e tmux new-session -As "$chosen" -c "$dir" "nvim ."
