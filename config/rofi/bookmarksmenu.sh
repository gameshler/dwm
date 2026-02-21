#!/bin/sh
set -eu

# Files (override via env if desired)
: "${HOME:?HOME not set}"
PERS_FILE="${PERS_FILE:-$HOME/.config/bookmarks/personal.txt}"
WORK_FILE="${WORK_FILE:-$HOME/.config/bookmarks/work.txt}"

# Rofi command
ROFI="rofi -dmenu -p 'Bookmarks:'"

# Browsers
FIREFOX="$(command -v firefox 2>/dev/null || true)"
BRAVE="$(command -v brave 2>/dev/null || command -v brave-browser 2>/dev/null || true)"
FALLBACK="$(command -v xdg-open 2>/dev/null || echo librewolf)"

# Ensure directory exists
mkdir -p "$(dirname "$PERS_FILE")"

# Ensure files exist with PROPER format
if [ ! -f "$PERS_FILE" ]; then
    cat >"$PERS_FILE" <<'EOF'
# personal bookmarks
youtube :: https://youtube.com
reddit :: https://reddit.com
EOF
fi

if [ ! -f "$WORK_FILE" ]; then
    cat >"$WORK_FILE" <<'EOF'
# work bookmarks
ArchWiki :: https://wiki.archlinux.org/title/Arch_Linux
GitHub :: https://github.com
EOF
fi

emit() {
    tag="$1"
    file="$2"
    [ -f "$file" ] || return 0
    grep -vE '^\s*(#|$)' "$file" | while IFS= read -r line; do
        case "$line" in
        *"::"*)
            lhs="${line%%::*}"
            rhs="${line#*::}"
            lhs="$(printf '%s' "$lhs" | sed 's/[[:space:]]*$//')"
            rhs="$(printf '%s' "$rhs" | sed 's/^[[:space:]]*//')"
            printf '[%s] %s :: %s\n' "$tag" "$lhs" "$rhs"
            ;;
        *)
            printf '[%s] %s :: %s\n' "$tag" "$line" "$line"
            ;;
        esac
    done
}

# Build combined list and show menu
choice="$({
    emit personal "$PERS_FILE"
    emit work "$WORK_FILE"
} | sort | eval "$ROFI" || true)"

[ -n "$choice" ] || exit 0

# Parse tag and raw URL - FIXED
tag="${choice%%]*}"
tag="${tag#\[}"
raw="${choice##* :: }"

# Strip inline comments and trim
raw="$(printf '%s' "$raw" |
    sed -e 's/[[:space:]]\+#.*$//' \
        -e 's/[[:space:]]\/\/.*$//' \
        -e 's/^[[:space:]]*//' \
        -e 's/[[:space:]]*$//' |
    sed 's/\[.*\]//g' | sed 's/([^)]*)//g')"

# Ensure scheme
case "$raw" in
    http://*|https://*|file://*|about:*|chrome:*) url="$raw" ;;
    *) url="https://$raw" ;;
esac

open_with() {
    cmd="$1"
    if [ -n "$cmd" ]; then
        nohup "$cmd" "$url" >/dev/null 2>&1 &
        exit 0
    fi
}

case "$tag" in
    personal) open_with "$FIREFOX" ;;
    work)     open_with "$BRAVE" ;;
esac

# Fallback
nohup $FALLBACK "$url" >/dev/null 2>&1 &
