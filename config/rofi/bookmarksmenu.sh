#!/bin/sh
set -eu

PERS_FILE="${PERS_FILE:-$HOME/.config/bookmarks/personal.txt}"
WORK_FILE="${WORK_FILE:-$HOME/.config/bookmarks/work.txt}"

ROFI="rofi -dmenu -p 'Bookmarks:'"

FIREFOX="$(command -v firefox || true)"
BRAVE="$(command -v brave || command -v brave-browser || true)"
FALLBACK="$(command -v xdg-open || echo firefox)"

mkdir -p "$(dirname "$PERS_FILE")"

set +e
if [ ! -f "$PERS_FILE" ]; then
    cat >"$PERS_FILE" <<'EOF'
# personal
youtube :: https://youtube.com
EOF
fi

if [ ! -f "$WORK_FILE" ]; then
    cat >"$WORK_FILE" <<'EOF'
# work
[docs] ArchWiki :: https://wiki.archlinux.org/title/Arch_Linux
EOF
fi
set -e

emit() {
  tag="$1"; file="$2"
  [ -f "$file" ] || return 0
  grep -vE '^\s*(#|$)' "$file" | while IFS= read -r line; do
    case "$line" in
      *"::"*)
        lhs="${line%%::*}"; rhs="${line#*::}"
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

choice="$({
  emit personal "$PERS_FILE"
  emit work     "$WORK_FILE"
} | sort | eval "$ROFI" || true)"

[ -n "$choice" ] || exit 0

tag="${choice%%]*}"; tag="${tag#[}"
raw="${choice##*:: }"

raw="$(printf '%s' "$raw" | sed -e 's/[[:space:]]\+#.*$//' -e 's/[[:space:]]*\/\/.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

case "$raw" in
  http://*|https://*|file://*|about:*|chrome:*) url="$raw" ;;
  *) url="https://$raw" ;;
esac

open_with() {
  cmd="$1"
  [ -n "$cmd" ] || return 1
  nohup "$cmd" --new-tab "$url" >/dev/null 2>&1 &
  exit 0
}

case "$tag" in
  personal) open_with "$FIREFOX" ;;
  work)     open_with "$BRAVE" ;;
esac

nohup "$FALLBACK" "$url" >/dev/null 2>&1 &
