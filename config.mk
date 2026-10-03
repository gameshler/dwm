# dwm version
VERSION = 0.3

# Customize below to fit your system

# paths
PREFIX = /usr/local
MANPREFIX = ${PREFIX}/share/man

X11INC = /usr/X11R6/include
X11LIB = /usr/X11R6/lib

# Xinerama, comment if you don't want it
XINERAMALIBS  = -lXinerama
XINERAMAFLAGS = -DXINERAMA

# freetype
FREETYPELIBS = -lfontconfig -lXft
FREETYPEINC = /usr/include/freetype2
# OpenBSD (uncomment)
#FREETYPEINC = ${X11INC}/freetype2

# includes and libs
INCS = -I${X11INC} -I${FREETYPEINC}
LIBS = -L${X11LIB} -lX11 ${XINERAMALIBS} ${FREETYPELIBS} -lXrender -lImlib2 -lX11-xcb -lxcb -lxcb-res ${KVMLIB}

# Optional compiler optimisations may create smaller binaries and
# faster code, but increases compile time.
# See https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
OPTIMISATIONS = -march=native -mtune=native -flto=auto -O3

# warnings
# -Wextra minus the three classes dwm's own design fires on every build:
# partial Keychord initialisers (80), keybinding handlers that ignore their Arg
# (13), and size_t/Atom compared against int counters (34). Re-enabling any of
# them buries the rest of -Wextra.
WARNINGS = -Wall -Wextra -Wno-unused-function -Wno-deprecated-declarations \
           -Wno-missing-field-initializers -Wno-unused-parameter -Wno-sign-compare

# flags
CPPFLAGS = -D_DEFAULT_SOURCE -D_BSD_SOURCE -D_XOPEN_SOURCE=700L -DVERSION=\"${VERSION}\" ${XINERAMAFLAGS}
CFLAGS   = ${OPTIMISATIONS} -std=c99 -pedantic ${WARNINGS} ${INCS} ${CPPFLAGS}
LDFLAGS  = ${LIBS}

# Solaris
#CFLAGS = -fast ${INCS} -DVERSION=\"${VERSION}\"
#LDFLAGS = ${LIBS}

# compiler and linker
CC = cc
