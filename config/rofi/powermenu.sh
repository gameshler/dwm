#!/bin/sh
set -eu

prompt="Power:"

menu() {
	printf "󰍃  logout\n"
	printf "󰤄  suspend\n"
	printf "󰒲  hibernate\n"
	printf "󰜉  reboot\n"
	printf "󰐥  shutdown\n"
}

choice="$(menu | rofi -dmenu -p "$prompt")"
[ -z "$choice" ] && exit 0

action="$(printf '%s' "$choice" | sed 's/^[^ ]*  //')"

case "$action" in
logout) loginctl terminate-session "${XDG_SESSION_ID-}" ;;
suspend) systemctl suspend ;;
hibernate) systemctl hibernate ;;
reboot) systemctl reboot ;;
shutdown) systemctl poweroff ;;
esac
