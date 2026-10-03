#!/bin/bash

outputs=$(xrandr --query | grep " connected" | cut -d" " -f1)

xrandr_cmd="xrandr"
prev_output=""

for output in $outputs; do
	native_res=$(xrandr --query | sed -n "/^$output connected/,/^[A-Z]/p" | grep -E "^   [0-9]+x[0-9]+" | head -n1 | awk '{print $1}')

	max_rate=$(xrandr --query | sed -n "/^$output connected/,/^[A-Z]/p" | grep "$native_res" | sed "s/$native_res//" | grep -oE "[0-9.]+" | sort -rn | head -n1)

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
