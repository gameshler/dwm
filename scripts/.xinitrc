#!/bin/bash

# A display manager sources .xprofile for us; startx does not.
# shellcheck source=/dev/null
[ -r "$HOME/.xprofile" ] && . "$HOME/.xprofile"

dbus-run-session -- sh -c ' exec dwm '
