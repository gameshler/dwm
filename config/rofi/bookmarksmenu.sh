#!/bin/sh
set -eu

# Files
# Put your files in .config/bookmarks/.
PERS_FILE="${PERS_FILE:-$HOME/.config/bookmarks/personal.txt}"
WORK_FILE="${WORK_FILE:-$HOME/.config/bookmarks/work.txt}"

# Rofi command
ROFI="rofi -dmenu -p 'Bookmarks:'"

# Browsers
# Choose your browsers accordingly
FIREFOX="$(command -v firefox || true)"
BRAVE="$(command -v brave || command -v brave-browser || true)"
FALLBACK="$(command -v xdg-open || echo librewolf)"

# Ensure files exist
if ! [ -f "$PERS_FILE" ]; then 
mkdir -p $PERS_FILE
cat >"$PERS_FILE" <<'EOF'
# personal
https://youtube.com
EOF
fi

if ! [ -f "$WORK_FILE" ]; then 
mkdir -p $WORK_FILE
cat >"$WORK_FILE" <<'EOF'
# work
[docs] ArchWiki :: https://wiki.archlinux.org/title/Arch_Linux
EOF
fi 

emit() {
    tag="$1"
    file="$2"
    [ -f "$file" ] || return 0
    # Output: "[tag] <display> :: <url or raw>"
    # We keep the whole line after '::' as the raw RHS, or the entire line if no '::'
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

# Build combined list
choice="$({
    emit personal "$PERS_FILE"
    emit work "$WORK_FILE"
} | sort | eval "$ROFI" || true)"

[ -n "$choice" ] || exit 0

# Parse tag and raw URL
tag="${choice%%]*}"
tag="${tag#\[}"
raw="${choice##* :: }"

# Strip inline comments and trim
raw="$(printf '%s' "$raw" |
    sed -e 's/[[:space:]]\+#.*$//' -e 's/[[:space:]]\/\/.*$//' \
        -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

# Ensure scheme
case "$raw" in
http://* | https://* | file://* | about:* | chrome:*) url="$raw" ;;
*) url="https://$raw" ;;
esac

# Pick browser by tag
open_with() {
    cmd="$1"
    if [ -n "$cmd" ]; then
        nohup "$cmd" --new-tab "$url" >/dev/null 2>&1 &
        exit 0
    fi
}

case "$tag" in
personal) open_with "$FIREFOX" ;;
work) open_with "$BRAVE" ;;
esac

# Fallback if specific browser not found
nohup $FALLBACK "$url" >/dev/null 2>&1 &
