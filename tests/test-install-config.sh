#!/bin/sh
# Installing the config over a running bar must not take the bar down.
#
# Quickshell watches ~/.config/quickshell and reloads on any change, so a copy
# that writes the tree file by file is one reload per file, and the ones landing
# mid-copy see a tree that does not compile: a shell.qml importing a file the
# copy has not reached yet. Measured under Xvfb against the previous install
# code, upgrading a running bar across a commit that adds one QML file killed
# the bar process outright - which is the defect this guards, and the reason the
# reported symptom was having to reboot.
#
# This drives the real `make install-config` target. Of its assertions, the one
# that bites deterministically is that the published directory is replaced
# rather than merged into: that holds only if the install stages a complete tree
# and renames it, which is the property that makes the bar survive. The
# liveness checks either side of it are the symptom itself, and a container with
# a fast disk often finishes the copy inside Quickshell's reload debounce, so
# they catch the defect on a loaded machine rather than every run. Verified
# against the pre-fix install code: it fails.
#
# Exits 77 when Quickshell or Xvfb is absent, which the Makefile treats as a
# skip.
set -eu

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "$0")/.." && pwd
)

for command_name in Xvfb quickshell xprop xwininfo xsetroot magick make pgrep; do
	if ! command -v "$command_name" >/dev/null 2>&1; then
		printf 'SKIP: %s is unavailable\n' "$command_name"
		exit 77
	fi
done
[ -x "$repo/dwm" ] || {
	printf 'SKIP: dwm is not built\n'
	exit 77
}

work=$(mktemp -d)
display=":$((($$ % 400) + 1300))"
xvfb_pid=
dwm_pid=
failures=0

cleanup() {
	set +e
	[ -z "$dwm_pid" ] || kill "$dwm_pid" 2>/dev/null
	pkill -f 'quickshell --path' 2>/dev/null
	[ -z "$xvfb_pid" ] || kill "$xvfb_pid" 2>/dev/null
	rm -rf "$work"
}
trap cleanup EXIT HUP INT TERM

fail() {
	printf '%s\n' "$1" >&2
	failures=$((failures + 1))
}

home=$work/home
mkdir -p "$home/.config" "$home/.local/bin"
cp "$repo/scripts/dwm-quickshell-state" "$repo/scripts/quickshell-launch.sh" \
	"$home/.local/bin/"
chmod +x "$home/.local/bin/"*

owner=$(id -un)

# Seed the home exactly as an earlier install would have left it.
make -C "$repo" install-config USER_HOME="$home" OWNER="$owner" >"$work/seed.log" 2>&1 || {
	tail -5 "$work/seed.log" >&2
	fail 'The seeding install-config failed.'
	exit 1
}

installed=$home/.config/quickshell

# Make the running bar visibly the old one. Magenta is nothing the real theme
# draws, so the pixel read afterwards cannot pass by accident.
sed -i.bak 's/readonly property string barBackground: "#000000"/readonly property string barBackground: "#FF00FF"/' \
	"$installed/core/Theme.qml"
rm -f "$installed/core/Theme.qml.bak"
grep -q '#FF00FF' "$installed/core/Theme.qml" || {
	fail 'Could not patch the seeded theme; the barBackground line has moved.'
	exit 1
}

# A file the repository does not ship. The install replaces the directory rather
# than merging into it, so this must be gone afterwards.
: >"$installed/stale-from-an-older-release.qml"

Xvfb "$display" -screen 0 1920x1080x24 -nolisten tcp \
	+extension GLX +render >"$work/xvfb.log" 2>&1 &
xvfb_pid=$!

waited=0
until DISPLAY=$display xprop -root >/dev/null 2>&1; do
	waited=$((waited + 1))
	[ "$waited" -lt 100 ] || {
		printf 'Xvfb did not start.\n' >&2
		exit 1
	}
	sleep 0.1
done

export DISPLAY="$display" HOME="$home"
export PATH="$home/.local/bin:$PATH"
DISPLAY=$display xsetroot -solid '#00FF00'

"$repo/dwm" >"$work/dwm.log" 2>&1 &
dwm_pid=$!

waited=0
until pgrep -f 'quickshell --path' >/dev/null 2>&1; do
	waited=$((waited + 1))
	[ "$waited" -lt 400 ] || {
		printf 'The bar never started.\n' >&2
		exit 1
	}
	sleep 0.1
done
sleep 5

bar_pixel() {
	DISPLAY=$display magick import -window root "$work/shot.png" 2>/dev/null
	magick "$work/shot.png" -format '%[pixel:p{960,12}]' info: 2>/dev/null
}

before=$(bar_pixel)
case $before in
*255,0,255*) ;;
*)
	fail "The seeded bar is not drawing its own background, so this proves nothing.
Read: $before"
	exit 1
	;;
esac

# The install under test, run while the bar is watching its config.
make -C "$repo" install-config USER_HOME="$home" OWNER="$owner" >"$work/install.log" 2>&1 ||
	fail 'install-config failed.'

sleep 10

# The defect: the bar process did not survive the install.
if ! pgrep -f 'quickshell --path' >/dev/null 2>&1; then
	fail 'The bar died during the install.'
fi

# And having survived, it has to be running what was just installed.
after=$(bar_pixel)
case $after in
*0,0,0*) ;;
*)
	fail "The bar did not pick up the installed config.
Expected the theme's black background, read: $after"
	;;
esac

if [ -e "$installed/stale-from-an-older-release.qml" ]; then
	fail 'The install merged into the old directory instead of replacing it.'
fi

# Staging directories are an implementation detail and must not outlive the run.
leftovers=$(find "$home/.config" -maxdepth 1 -name '.*.dwm-staged.*' \
	-o -maxdepth 1 -name '.*.dwm-previous.*' 2>/dev/null)
if [ -n "$leftovers" ]; then
	fail "The install left staging directories behind:
$leftovers"
fi

if [ "$failures" -ne 0 ]; then
	printf 'test-install-config: %s assertion(s) failed\n' "$failures" >&2
	exit 1
fi

printf 'Config install over a running bar: PASS\n'
