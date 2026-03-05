#!/bin/bash

dbus-run-session -- sh -c '
  ~/.local/share/dwm/polybar/launch.sh &
  xrandr --output DisplayPort-1 --mode 1920x1080 --rate 239.76 &
  exec dwm
'
