#!/usr/bin/env bash
set -euo pipefail

THEME="minimal"

command -v polybar >/dev/null 2>&1 || {
    echo "ERROR: polybar not installed" >&2
    exit 1
}

if pgrep -u "$UID" -x polybar >/dev/null 2>&1; then
    killall polybar
    while pgrep -u "$UID" -x polybar >/dev/null 2>&1; do
        sleep 0.2
    done
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -f "$HOME/.config/polybar/themes/$THEME/config.ini" ]; then
    CONFIG_DIR="$HOME/.config/polybar"
elif [ -f "$SCRIPT_DIR/themes/$THEME/config.ini" ]; then
    CONFIG_DIR="$SCRIPT_DIR"
else
    echo "ERROR: No config found for theme '$THEME'" >&2
    exit 1
fi

CONFIG_FILE="$CONFIG_DIR/themes/$THEME/config.ini"
LAPTOP_CONFIG_FILE="$CONFIG_DIR/themes/$THEME/laptop-config.ini"

if [ -d /sys/class/power_supply ]; then
    for dev in /sys/class/power_supply/*; do
        [ -f "$dev/type" ] || continue

        case "$(cat "$dev/type")" in
        Battery)
            export DWM_BATTERY="$(basename "$dev")"
            CONFIG_FILE="$LAPTOP_CONFIG_FILE"
            ;;
        Mains)
            export DWM_ADAPTER="$(basename "$dev")"
            ;;
        esac
    done

fi

[ -f "$CONFIG_FILE" ] || {
    echo "ERROR: Config file missing: $CONFIG_FILE" >&2
    exit 1
}

if command -v xrandr >/dev/null 2>&1; then
    XRANDR_OUTPUT="$(xrandr --query)"

    mapfile -t MONITORS < <(
        printf "%s\n" "$XRANDR_OUTPUT" | grep " connected" | cut -d" " -f1
    )

    MONITOR_COUNT="${#MONITORS[@]}"

    PRIMARY_MONITOR="$(
        printf "%s\n" "$XRANDR_OUTPUT" | grep " connected primary" | cut -d" " -f1
    )"

    if [ -z "$PRIMARY_MONITOR" ] && [ "$MONITOR_COUNT" -gt 0 ]; then
        PRIMARY_MONITOR="${MONITORS[0]}"
    fi

else
    MONITOR_COUNT=0
fi
launch_bar() {
    MONITOR="$1" polybar "$2" -c "$CONFIG_FILE" &
}

case "${MONITOR_COUNT:-0}" in
0)
    echo "No monitors detected (or xrandr missing), launching fallback"
    polybar main -c "$CONFIG_FILE" &
    ;;
1)
    launch_bar "${MONITORS[0]}" main
    ;;
*)
    for monitor in "${MONITORS[@]}"; do
        if [ "$monitor" = "$PRIMARY_MONITOR" ]; then
            launch_bar "$monitor" main
        else
            launch_bar "$monitor" secondary
        fi
    done
    ;;
esac
