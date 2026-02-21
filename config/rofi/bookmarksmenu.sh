#!/bin/sh
set -eu

# Files
PERS_FILE="$HOME/.config/bookmarks/personal.txt"
WORK_FILE="$HOME/.config/bookmarks/work.txt"

# Rofi command
ROFI="rofi -dmenu -p 'Bookmarks:'"

# Browsers
FIREFOX="$(command -v firefox || true)"
BRAVE="$(command -v brave || command -v brave-browser || true)"
FALLBACK="$(command -v xdg-open || echo librewolf)"

# Ensure directories and files exist
mkdir -p "$(dirname "$PERS_FILE")"
[ -f "$PERS_FILE" ] || cat >"$PERS_FILE" <<'EOF'
# personal
https://youtube.com
EOF
[ -f "$WORK_FILE" ] || cat >"$WORK_FILE" <<'EOF'
# work
[docs] Arch Wiki :: https://wiki.archlinux.org/title/Arch_Linux
EOF

# Emit function to print bookmarks
emit() {
  tag="$1"; file="$2"
  [ -f "$file" ] || return 0
  grep -vE '^\s*(#|$)' "$file" | while IFS= read -r line; do
    case "$line" in
      *"::"*)
        lhs="${line%%::*}"; rhs="${line#*::}"
        lhs="$(printf '%s' "$lhs" | sed 's/[[:space:]]*$//')"  # trim spaces from lhs
        rhs="$(printf '%s' "$rhs" | sed 's/^[[:space:]]*//')"  # trim spaces from rhs
        printf '[%s] %s :: %s\n' "$tag" "$lhs" "$rhs"
        ;;
      *)
        # Handle single URL, extract domain as title
        url="$line"
        title="$(echo "$url" | sed -E 's#^https?://([^/]+).*#\1#')"  # Extract domain (like youtube.com)
        printf '[%s] %s :: %s\n' "$tag" "$title" "$url"
        ;;
    esac
  done
}

# Build combined list of bookmarks
choice="$({
  emit personal "$PERS_FILE"
  emit work     "$WORK_FILE"
} | sort | eval "$ROFI" || true)"

[ -n "$choice" ] || exit 0

# Parse the selected bookmark (tag and URL)
tag="${choice%%]*}"; tag="${tag#\[}"
raw="${choice##* :: }"

# Clean the raw URL (strip comments and whitespace)
raw="$(printf '%s' "$raw" \
  | sed -e 's/[[:space:]]\+#.*$//' -e 's/[[:space:]]\/\/.*$//' \
        -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

# Ensure the URL has a scheme (http:// or https://)
case "$raw" in
  http://*|https://*|file://*|about:*|chrome:*) url="$raw" ;;
  *) url="https://$raw" ;;  # Default to https:// if no scheme
esac

# Open the URL in the correct browser based on the tag
open_with() {
  cmd="$1"
  if [ -n "$cmd" ]; then
    nohup "$cmd" --new-tab "$url" >/dev/null 2>&1 & exit 0
  fi
}

# Use appropriate browser
case "$tag" in
  personal) open_with "$FIREFOX" ;;
  work)     open_with "$BRAVE" ;;
esac

# Fallback browser if no specific browser is found
nohup $FALLBACK "$url" >/dev/null 2>&1 &
