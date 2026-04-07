#!/bin/bash

browser=$(xdg-settings get default-web-browser)

case $browser in
google-chrome* | brave-browser* | microsoft-edge* | opera* | vivaldi* | helium-browser* | librewolf*) ;;
*) browser="librewolf.desktop" ;;
esac

exec $(sed -n 's/^Exec=\([^ ]*\).*/\1/p' /usr/share/applications/"$browser" 2>/dev/null | head -1) --app="$1" "${@:2}" >/dev/null 2>&1
