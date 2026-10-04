#!/bin/bash
# Enables every connected output at its native mode and highest refresh rate,
# arranged left to right. autostart[] in config.h runs this at session start.
#
# Order is the part worth explaining. xrandr lists outputs in connector-name
# order, so placing each one --right-of the previous arranges the desk by what
# the cables happen to be called: a monitor sitting physically on the left ends
# up to the right of the other one, and the pointer has to travel the wrong way
# to reach it. Nothing xrandr reports says where the panels actually are, so the
# arrangement has to be stated.
#
# ~/.config/dwm/monitors.conf holds it: one output per line, left to right, the
# first line primary. Blank lines and # comments are ignored, names that are not
# connected are skipped, and any connected output the file does not mention is
# appended on the right so plugging in a new monitor still lights it up. With no
# such file the old connector-name order is used unchanged.
#
#     # my desk, left to right
#     HDMI-1
#     DP-2
#
# `xrandr --query | grep " connected"` prints the names to put in it.

layout_file=${DWM_MONITOR_LAYOUT:-${XDG_CONFIG_HOME:-$HOME/.config}/dwm/monitors.conf}

# Space separated on one line: the membership tests below are space delimited,
# and cut leaves one name per line.
connected=$(xrandr --query | grep " connected" | cut -d" " -f1 | tr '\n' ' ')

in_list() {
	case " $2 " in
	*" $1 "*) return 0 ;;
	*) return 1 ;;
	esac
}

# The layout file first, in its own order, then whatever it left out.
ordered=""
if [[ -r $layout_file ]]; then
	while IFS= read -r line || [[ -n $line ]]; do
		name=${line%%#*}
		name=${name//[[:space:]]/}
		[[ -n $name ]] || continue
		in_list "$name" "$connected" || continue
		in_list "$name" "$ordered" && continue
		ordered+="$name "
	done <"$layout_file"
fi

for output in $connected; do
	in_list "$output" "$ordered" || ordered+="$output "
done

# Native mode and its fastest rate, read out of the output's own mode block.
#
# The rates live on the mode line, suffixed with * for current and + for
# preferred: "   2560x1440    143.86*+ 120.00   59.95". Reading them by grepping
# the whole query for the resolution also matched the `connected` header, which
# carries the panel's physical size - so the rate came back as 597, the width in
# millimetres, and xrandr rejected the entire command. Nothing was ever applied.
mode_and_rate() {
	xrandr --query | awk -v out="$1" '
		$1 == out && $2 == "connected" { inblock = 1; next }
		inblock && /^[^ \t]/ { inblock = 0 }
		inblock && $1 ~ /^[0-9]+x[0-9]+$/ {
			best = 0
			for (i = 2; i <= NF; i++) {
				rate = $i
				gsub(/[*+]/, "", rate)
				if (rate + 0 > best) {
					best = rate + 0
				}
			}
			if (best > 0) {
				printf "%s %.2f\n", $1, best
			}
			exit
		}'
}

xrandr_cmd="xrandr"
prev_output=""

for output in $ordered; do
	read -r native_res max_rate <<<"$(mode_and_rate "$output")"

	if [ -n "$native_res" ] && [ -n "$max_rate" ]; then
		if [ -z "$prev_output" ]; then
			xrandr_cmd="$xrandr_cmd --output $output --primary --mode $native_res --rate $max_rate"
		else
			xrandr_cmd="$xrandr_cmd --output $output --mode $native_res --rate $max_rate --right-of $prev_output"
		fi
		prev_output=$output
	fi
done

eval "$xrandr_cmd"
