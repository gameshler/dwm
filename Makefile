# dwm - dynamic window manager
# See LICENSE file for copyright and license details.

include config.mk

USER_HOME ?= $(shell getent passwd $(or $(SUDO_USER),$(USER)) 2>/dev/null | cut -d: -f6)
OWNER     := $(or $(SUDO_USER),$(USER))
CFG_DIR   := ${USER_HOME}/.config
BIN_DIR   := ${USER_HOME}/.local/bin

SRC = drw.c dwm.c util.c
OBJ = ${SRC:.c=.o}

all: dwm

.c.o:
	${CC} -c ${CFLAGS} $<

${OBJ}: config.h config.mk

config.h:
	cp config.def.h $@

dwm: ${OBJ}
	${CC} -o $@ ${OBJ} ${LDFLAGS}

clean:
	rm -f dwm ${OBJ} *.orig *.rej

lint:
	@command -v shellcheck >/dev/null || { echo "install shellcheck"; exit 1; }
	@command -v shfmt >/dev/null || { echo "install shfmt"; exit 1; }
	files=$$(shfmt -f config debug scripts tests tools install.sh); \
		shellcheck -x $$files && shfmt -d $$files
	tools/qml-lint.sh

# check-bar-xvfb exits 77 - treated as a skip - when Quickshell or Xvfb is
# absent.
check: check-design-system check-tray check-layout check-state-protocol \
	check-launcher check-state check-session-action check-display-setup \
	check-bar-xvfb check-menus-xvfb check-install-config

check-design-system:
	tests/test-quickshell-design-system.sh

check-tray:
	tests/test-quickshell-tray.sh

check-layout:
	tests/test-quickshell-layout.sh

check-state-protocol:
	tests/test-state-protocol.sh

check-launcher:
	tests/test-quickshell-launcher.sh

check-state:
	tests/test-dwm-quickshell-state.sh

check-session-action:
	tests/test-session-action.sh

check-display-setup:
	tests/test-display-setup.sh

check-bar-xvfb: dwm
	@status=0; tests/test-bar-xvfb.sh || status=$$?; \
		if [ "$$status" -eq 77 ]; then exit 0; fi; \
		exit "$$status"

check-menus-xvfb: dwm
	@status=0; tests/test-menus-xvfb.sh || status=$$?; \
		if [ "$$status" -eq 77 ]; then exit 0; fi; \
		exit "$$status"

check-install-config: dwm
	@status=0; tests/test-install-config.sh || status=$$?; \
		if [ "$$status" -eq 77 ]; then exit 0; fi; \
		exit "$$status"

# Each config directory is staged beside its target and moved into place, not
# copied over it. Quickshell watches ~/.config/quickshell and reloads on any
# change, so a copy that writes thirty files one at a time is thirty reloads,
# and the ones landing mid-copy see a tree that does not compile - a shell.qml
# importing a file the copy has not reached yet. Measured under Xvfb, upgrading
# a running bar across a commit that adds one QML file: copying in place killed
# the bar outright, staging and renaming gave one clean reload onto the new
# config.
#
# Ownership and the executable bits are set on the staged tree, so what appears
# at the published path is correct from the instant it appears; copying in place
# left the files root-owned for the length of the copy. The two renames are
# within one directory, so the moment the path does not exist is a syscall wide
# rather than the length of a copy.
#
# Split out of install so it can be exercised without root, which is what
# tests/test-install-config.sh does.
install-config:
	install -d -o ${OWNER} ${CFG_DIR}
	for dir in config/*/; do \
		name=$$(basename "$$dir"); \
		dst=${CFG_DIR}/$$name; \
		staged=${CFG_DIR}/.$$name.dwm-staged.$$$$; \
		previous=${CFG_DIR}/.$$name.dwm-previous.$$$$; \
		rm -rf ${CFG_DIR}/.$$name.dwm-staged.* ${CFG_DIR}/.$$name.dwm-previous.*; \
		cp -rfLT "$$dir" "$$staged"; \
		find "$$staged" -name '*.sh' -o -name '*.py' 2>/dev/null | xargs -r chmod +x; \
		chown -R ${OWNER}: "$$staged"; \
		if [ -e "$$dst" ] || [ -L "$$dst" ]; then mv "$$dst" "$$previous"; fi; \
		mv "$$staged" "$$dst"; \
		rm -rf "$$previous"; \
	done

install: all
	@echo "==> Installing DWM..."
	mkdir -p ${DESTDIR}${PREFIX}/bin
	install -Dm755 dwm ${DESTDIR}${PREFIX}/bin/dwm
	mkdir -p ${DESTDIR}${MANPREFIX}/man1
	sed "s/VERSION/${VERSION}/g" < dwm.1 > ${DESTDIR}${MANPREFIX}/man1/dwm.1
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/dwm.1
	@echo "==> Creating Xsessions..."
	mkdir -p /usr/share/xsessions/
	test -f /usr/share/xsessions/dwm.desktop || install -Dm644 dwm.desktop /usr/share/xsessions/
	test -f ${USER_HOME}/.xinitrc || install -Dm644 -o ${OWNER} scripts/.xinitrc ${USER_HOME}/.xinitrc
	test -f ${USER_HOME}/.xprofile || install -Dm644 -o ${OWNER} scripts/.xprofile ${USER_HOME}/.xprofile

	${MAKE} install-config USER_HOME=${USER_HOME} OWNER=${OWNER}

	@echo "==> Installing scripts..."
	install -d -o ${OWNER} ${BIN_DIR}
	for f in scripts/*; do \
		install -Dm755 -o ${OWNER} "$$f" ${BIN_DIR}/$$(basename $$f); \
	done

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/dwm \
		${DESTDIR}${MANPREFIX}/man1/dwm.1 \
		${DESTDIR}/usr/share/xsessions/dwm.desktop

release: dwm
	rm -rf release
	mkdir -p release
	cp -f dwm dwm.desktop scripts/.xinitrc scripts/.xprofile release/
	cp -rf config scripts release/
	tar -czf release/Kaless-${VERSION}.tar.gz -C release dwm dwm.desktop .xinitrc .xprofile config scripts

.PHONY: all clean lint install install-config uninstall release check \
	check-design-system check-tray check-layout check-state-protocol \
	check-launcher check-state check-session-action check-display-setup \
	check-bar-xvfb check-menus-xvfb check-install-config
