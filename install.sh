#!/bin/sh
# Standalone installer for this dwm build on Arch-based systems. Run it from a
# clone of this repo as your normal user; it calls sudo only where root is
# needed.
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Required: dwm, the keybindings in config.h and the bar all call these by name.
REQUIRED_PACKAGES="
base-devel git
libx11 libxinerama libxft libxcb imlib2
xorg-server xorg-xinit xorg-xprop xorg-xrandr xorg-xsetroot xorg-xset xorg-xrdb
ghostty rofi picom dunst feh flameshot dex mate-polkit
quickshell wmctrl xdotool
xdg-utils xdg-user-dirs xdg-desktop-portal-gtk
ttf-firacode-nerd inter-font noto-fonts-emoji
"

# Optional: the bar hides each module when its tool is missing. bluez is not
# here on purpose - it is installed only when the machine has an adapter, by
# install_packages below.
BAR_PACKAGES="
networkmanager network-manager-applet
pipewire pipewire-pulse pavucontrol
papirus-icon-theme
pacman-contrib
"

# The rest of the desktop this config is built around.
DESKTOP_PACKAGES="
thunar thunar-archive-plugin tumbler gvfs xarchiver
xclip unzip nwg-look alsa-utils gnome-keyring flatpak
xscreensaver tldr tmux
"

info() { printf '==> %s\n' "$1"; }
warn() { printf 'WARNING: %s\n' "$1" >&2; }
die() {
	printf 'ERROR: %s\n' "$1" >&2
	exit 1
}

check_system() {
	command -v pacman >/dev/null 2>&1 ||
		die "this installer supports Arch-based systems only (no pacman found)"
	[ "$(id -u)" -ne 0 ] ||
		die "run this as your normal user, not as root - it calls sudo itself"
	[ -f "$REPO_DIR/dwm.c" ] ||
		die "run this from a clone of the dwm repo"
}

# Read from /sys rather than from a tool, because this has to answer before
# bluez is installed. The directory exists whenever the subsystem is built into
# the kernel and is empty when no adapter is attached, so the test is for
# contents and not for the directory. An unmatched glob stays literal in POSIX
# sh, which is why each entry is tested with -e.
has_bluetooth_adapter() {
	for dev in /sys/class/bluetooth/*; do
		if [ -e "$dev" ]; then
			return 0
		fi
	done
	return 1
}

install_packages() {
	info "Installing packages"
	# Deliberate word splitting: the lists above are whitespace separated.
	# shellcheck disable=SC2086
	sudo pacman -S --needed --noconfirm \
		$REQUIRED_PACKAGES $BAR_PACKAGES $DESKTOP_PACKAGES

	# On a desktop with no adapter bluez is dead weight and a service with
	# nothing to manage, and the bar hides the indicator either way.
	if has_bluetooth_adapter; then
		info "Bluetooth adapter found - installing bluez"
		sudo pacman -S --needed --noconfirm bluez bluez-utils
	else
		warn "no bluetooth adapter found - skipping bluez"
		printf '    The bar hides its Bluetooth indicator when there is no\n'
		printf '    adapter. If you add one later:\n\n'
		printf '        sudo pacman -S --needed bluez bluez-utils\n'
		printf '        sudo systemctl enable --now bluetooth\n\n'
	fi
}

enable_bluetooth() {
	has_bluetooth_adapter || return 0
	command -v bluetoothctl >/dev/null 2>&1 || return 0
	systemctl is-active --quiet bluetooth && return 0

	# Arch enables nothing by preset. With the service stopped, `bluetoothctl
	# show` prints no "Powered:" line, so the bar reads that as no adapter and
	# hides the indicator - correct, but indistinguishable from a bug.
	info "Enabling bluetooth.service"
	sudo systemctl enable --now bluetooth ||
		warn "could not enable bluetooth.service - the Bluetooth indicator will stay hidden"
}

build_and_install() {
	# Build unprivileged so the objects stay owned by you, then hand only the
	# install step to root.
	info "Building dwm"
	make -C "$REPO_DIR" clean
	make -C "$REPO_DIR"

	info "Installing dwm, configs and scripts"
	sudo make -C "$REPO_DIR" install
}

install_backgrounds() {
	# config.h autostarts feh against this directory.
	bg_dir="$HOME/Pictures/backgrounds"
	info "Installing wallpapers to $bg_dir"
	mkdir -p "$bg_dir"
	# An empty backgrounds/ leaves the glob unexpanded, which would fail cp on the
	# very last step of the install.
	if [ -n "$(ls -A "$REPO_DIR/backgrounds" 2>/dev/null)" ]; then
		cp -f "$REPO_DIR"/backgrounds/* "$bg_dir/"
	else
		warn "no wallpapers in $REPO_DIR/backgrounds - skipping"
	fi
}

# gsettings needs a D-Bus session bus to commit to dconf, and run from a TTY on
# a fresh install there is none. dbus-run-session supplies a throwaway one; the
# values still land in ~/.config/dconf/user and outlive it. Returns non-zero
# only when there is no bus and no way to make one.
with_session_bus() {
	if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
		sh -c "$1"
	elif command -v dbus-run-session >/dev/null 2>&1; then
		dbus-run-session -- sh -c "$1"
	else
		return 1
	fi
}

configure_dark_mode() {
	# GTK reads config/gtk-3.0 and config/gtk-4.0 directly, but libadwaita and
	# Qt 6 ask the desktop portal instead, and its answers live in dconf.
	if ! command -v gsettings >/dev/null 2>&1; then
		warn "gsettings not found - GTK4 and Qt applications may stay light"
		return 0
	fi

	info "Setting the desktop portal to dark"
	iface=org.gnome.desktop.interface

	# Papirus, not Papirus-Dark: the Dark variant ships no application icons and
	# inherits breeze-dark, which would empty the bar's app dock and tray.
	if ! with_session_bus "
		gsettings set $iface color-scheme 'prefer-dark'
		gsettings set $iface gtk-theme 'Adwaita-dark'
		gsettings set $iface icon-theme 'Papirus'
	"; then
		warn "no session bus and no dbus-run-session - GTK4 and Qt applications may stay light"
		return 0
	fi

	# gsettings exits 0 even when the dconf commit failed, so a `|| warn` on the
	# set itself can never fire. Reading one key back is the only honest check.
	scheme="$(with_session_bus "gsettings get $iface color-scheme" 2>/dev/null)" || scheme=""
	case "$scheme" in
	*prefer-dark*) ;;
	*)
		warn "the portal colour scheme did not take - GTK4 and Qt applications may stay light"
		;;
	esac
}

report_display_manager() {
	for dm in gdm sddm lightdm ly; do
		if systemctl is-enabled "$dm" >/dev/null 2>&1; then
			info "Display manager: $dm - choose dwm at the login screen"
			return 0
		fi
	done

	warn "no display manager is enabled"
	printf '    Either log in on a TTY and run startx - make install put an\n'
	printf '    .xinitrc in your home directory for exactly that - or install\n'
	printf '    one, for example:\n\n'
	printf '        sudo pacman -S sddm && sudo systemctl enable sddm\n\n'
}

check_system
install_packages
build_and_install
install_backgrounds
enable_bluetooth
configure_dark_mode
report_display_manager

info "Done. Log out and back in to start dwm."
