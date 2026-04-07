#!/usr/bin/env bash

set -euo pipefail

# Use real grep, not rg alias
grep() { command grep "$@"; }

SERVICE_NAME="wm-graphical-session"
SERVICE_DIR="${HOME}/.config/systemd/user"
SERVICE_FILE="${SERVICE_DIR}/${SERVICE_NAME}.service"

# ─── Pre-flight checks ───
echo "Pre-flight Checks"

if ! command -v systemctl &>/dev/null; then
    echo "systemctl not found — this script requires systemd"
    exit 1
fi
echo "systemd available"

if ! systemctl --user status &>/dev/null 2>&1; then
    echo "systemd user session not running (is lingering enabled or are you in a login session?)"
    exit 1
fi
echo "systemd user session active"

# Check that the targets exist
for target in graphical-session.target xdg-desktop-autostart.target; do
    if systemctl --user cat "$target" &>/dev/null 2>&1; then
        echo "$target found"
    else
        echo "$target not found — systemd version may be too old (need 246+)"
        exit 1
    fi
done

# ─── Current state ───
echo "Current State"

GS_STATE=$(systemctl --user is-active graphical-session.target 2>/dev/null || echo "inactive")
XDG_STATE=$(systemctl --user is-active xdg-desktop-autostart.target 2>/dev/null || echo "inactive")
echo "graphical-session.target: ${GS_STATE}"
echo "xdg-desktop-autostart.target: ${XDG_STATE}"

if [[ "$GS_STATE" == "active" && "$XDG_STATE" == "active" ]]; then
    echo "XDG autostart is already active"
    echo ""
    read -rp "  Re-install anyway? [y/N] " REPLY
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        echo "  Nothing to do."
        exit 0
    fi
fi

# ─── Detect autostart entries ──
echo "Autostart Entries"

USER_ENTRIES=0
SYSTEM_ENTRIES=0
if [[ -d "${HOME}/.config/autostart" ]]; then
    USER_ENTRIES=$(find "${HOME}/.config/autostart" -name '*.desktop' 2>/dev/null | wc -l)
fi
if [[ -d "/etc/xdg/autostart" ]]; then
    SYSTEM_ENTRIES=$(find /etc/xdg/autostart -name '*.desktop' 2>/dev/null | wc -l)
fi
echo "User autostart entries (~/.config/autostart/): ${USER_ENTRIES}"
echo "System autostart entries (/etc/xdg/autostart/): ${SYSTEM_ENTRIES}"

if [[ $USER_ENTRIES -gt 0 ]]; then
    find "${HOME}/.config/autostart" -name '*.desktop' -printf '    %f\n' 2>/dev/null
fi

# ─── Create systemd user service ──
echo "Installing Systemd User Service"

mkdir -p "$SERVICE_DIR"

if [[ -f "$SERVICE_FILE" ]]; then
    echo "Service file already exists: ${SERVICE_FILE}"
    echo "Overwriting with updated version"
fi

cat >"$SERVICE_FILE" <<'UNIT'
[Unit]
Description=Window Manager Graphical Session (XDG Autostart)
Documentation=man:systemd.special(7)
BindsTo=graphical-session.target
Wants=graphical-session.target xdg-desktop-autostart.target
After=basic.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true

[Install]
WantedBy=default.target
UNIT

echo "Created ${SERVICE_FILE}"

# ─── Enable the service ──
echo "Enabling Service"

systemctl --user daemon-reload
echo "Reloaded systemd user daemon"

systemctl --user enable "$SERVICE_NAME.service" 2>/dev/null
echo "Enabled ${SERVICE_NAME}.service"

# ─── Activate now if in a graphical session ──
echo "Activating"

if [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    # Export display environment to systemd
    EXPORT_VARS=(DISPLAY)
    [[ -n "${XAUTHORITY:-}" ]] && EXPORT_VARS+=(XAUTHORITY)
    [[ -n "${WAYLAND_DISPLAY:-}" ]] && EXPORT_VARS+=(WAYLAND_DISPLAY)
    [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] && EXPORT_VARS+=(XDG_CURRENT_DESKTOP)
    [[ -n "${XDG_SESSION_TYPE:-}" ]] && EXPORT_VARS+=(XDG_SESSION_TYPE)

    systemctl --user import-environment "${EXPORT_VARS[@]}"
    echo "Imported environment: ${EXPORT_VARS[*]}"

    if command -v dbus-update-activation-environment &>/dev/null; then
        dbus-update-activation-environment --systemd "${EXPORT_VARS[@]}" 2>/dev/null || true
        echo "Updated D-Bus activation environment"
    fi

    systemctl --user start "$SERVICE_NAME.service" 2>/dev/null || true
    echo "Started ${SERVICE_NAME}.service"
else
    echo "No graphical session detected — service will activate on next login"
fi

# ─── Detect xinitrc and offer to patch it ───
echo "Shell Startup Integration"

ENV_SNIPPET='# Export display env to systemd user session (needed for XDG autostart)
systemctl --user import-environment DISPLAY XAUTHORITY 2>/dev/null
dbus-update-activation-environment --systemd DISPLAY XAUTHORITY 2>/dev/null'

XINITRC_PATHS=(
    "${HOME}/.xinitrc"
    "${HOME}/.local/share/dwm/.xinitrc"
    "${HOME}/.config/X11/xinitrc"
)

PATCHED=false
for rc in "${XINITRC_PATHS[@]}"; do
    if [[ -f "$rc" ]]; then
        echo "Found xinitrc: ${rc}"
        if grep -q "import-environment DISPLAY" "$rc" 2>/dev/null; then
            echo "Environment export already present in ${rc}"
            PATCHED=true
        else
            echo ""
            read -rp "  Add environment export to ${rc}? [Y/n] " REPLY
            if [[ ! "$REPLY" =~ ^[Nn]$ ]]; then
                # Insert after the shebang line
                SHEBANG=$(head -1 "$rc")
                if [[ "$SHEBANG" == "#!"* ]]; then
                    # Insert after shebang and any immediate blank line
                    LINENUM=2
                    while IFS= read -r line; do
                        if [[ -z "$line" ]]; then
                            LINENUM=$((LINENUM + 1))
                        else
                            break
                        fi
                    done < <(tail -n +2 "$rc")
                    {
                        head -n $((LINENUM - 1)) "$rc"
                        echo ""
                        echo "$ENV_SNIPPET"
                        echo ""
                        tail -n +"$LINENUM" "$rc"
                    } >"${rc}.tmp"
                    mv "${rc}.tmp" "$rc"
                    chmod +x "$rc"
                else
                    # No shebang, prepend
                    {
                        echo "$ENV_SNIPPET"
                        echo ""
                        cat "$rc"
                    } >"${rc}.tmp"
                    mv "${rc}.tmp" "$rc"
                fi
                echo "Patched ${rc}"
                PATCHED=true
            fi
        fi
    fi
done

if [[ "$PATCHED" == false ]]; then
    echo "No xinitrc found to patch"
    echo "If you use a xinitrc or session script, add these lines before your WM exec:"
    echo ""
    echo -e "${ENV_SNIPPET}"
    echo ""
fi

# ─── Verify ──
echo "Verification"

GS_FINAL=$(systemctl --user is-active graphical-session.target 2>/dev/null || echo "inactive")
XDG_FINAL=$(systemctl --user is-active xdg-desktop-autostart.target 2>/dev/null || echo "inactive")
SVC_FINAL=$(systemctl --user is-active "$SERVICE_NAME.service" 2>/dev/null || echo "inactive")
SVC_ENABLED=$(systemctl --user is-enabled "$SERVICE_NAME.service" 2>/dev/null || echo "disabled")

echo "${SERVICE_NAME}.service: ${SVC_FINAL} (${SVC_ENABLED})"
echo "graphical-session.target: ${GS_FINAL}"
echo "xdg-desktop-autostart.target: ${XDG_FINAL}"

# List which autostart services systemd generated
GENERATED=$(systemctl --user list-unit-files --type=service 2>/dev/null | grep "@autostart" | wc -l)
if [[ $GENERATED -gt 0 ]]; then
    echo "Systemd generated ${GENERATED} autostart service(s):"
    systemctl --user list-unit-files --type=service 2>/dev/null | grep "@autostart" | while read -r unit state _; do
        STATUS=$(systemctl --user is-active "$unit" 2>/dev/null || echo "inactive")
        if [[ "$STATUS" == "active" || "$STATUS" == "inactive" ]]; then
            SHORT=$(echo "$unit" | sed 's/app-//;s/@autostart.service//;s/\\x2d/-/g')
            echo "    ${SHORT} (${STATUS})"
        fi
    done
fi

# ─── Summary ──
if [[ "$GS_FINAL" == "active" ]]; then
    echo -e "  XDG autostart is active and will persist across logins."
else
    echo -e "  Service installed and enabled — will activate on next login."
fi
