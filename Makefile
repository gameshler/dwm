# dwm - dynamic window manager
# See LICENSE file for copyright and license details.

include config.mk

USER_HOME ?= $(shell getent passwd $(or $(SUDO_USER),$(USER)) 2>/dev/null | cut -d: -f6)
OWNER     := $(or $(SUDO_USER),$(USER))
CFG_DIR   := ${USER_HOME}/.config

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
	mkdir -p /etc/xdg/autostart
	install -Dm644 set-refresh.desktop /etc/xdg/autostart/set-refresh.desktop
	test -f ${USER_HOME}/.xinitrc || install -Dm644 scripts/.xinitrc ${USER_HOME}/.xinitrc

	@echo "==> Installing config directories..."
	for dir in config/*/; do \
		dst=${CFG_DIR}/$$(basename "$$dir"); \
		[ -L "$$dst" ] && rm -f "$$dst"; \
		cp -rfL --remove-destination "$$dir" "$$dst"; \
	done
	
	for dir in config/*/; do \
		b=$$(basename $$dir); \
		find "${CFG_DIR}/$$b" -name '*.sh' -o -name '*.py' 2>/dev/null | xargs -r chmod +x; \
		chown -R ${OWNER}: "${CFG_DIR}/$$b"; \
	done

	mkdir -p ${DESTDIR}${PREFIX}/bin
	install -Dm755 scripts/* ${DESTDIR}${PREFIX}/bin/

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/dwm \
		${DESTDIR}${MANPREFIX}/man1/dwm.1 \
		${DESTDIR}/usr/share/xsessions/dwm.desktop

release: dwm
	mkdir -p release
	cp -f dwm dwm.desktop set-refresh.desktop .xinitrc release/	
	cp -rf config scripts release/
	tar -czf release/Kaless-${VERSION}.tar.gz -C release dwm dwm.desktop set-refresh.desktop .xinitrc config scripts

.PHONY: all clean install uninstall release
