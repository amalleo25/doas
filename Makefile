CC?=clang
YACC?=yacc
BIN=doas
PREFIX?=/usr/local
MANDIR?=$(DESTDIR)$(PREFIX)/man
SYSCONFDIR?=$(DESTDIR)$(PREFIX)/etc
OBJECTS=doas.o env.o compat/execvpe.o compat/reallocarray.o y.tab.o
OPT?=-O2
# Can set GLOBAL_PATH here to set PATH for target user.
# TARGETPATH=-DGLOBAL_PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\"
CFLAGS+=-Wall $(OPT) -DUSE_PAM -DDOAS_CONF=\"${SYSCONFDIR}/doas.conf\" $(TARGETPATH)
CPPFLAGS+=-include compat/compat.h
LDFLAGS+=-lpam
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    LDFLAGS+=-lpam_misc
    CPPFLAGS+=-Icompat
    CFLAGS+=-D_GNU_SOURCE
    COMPAT+=closefrom.o errc.o getprogname.o setprogname.o strlcat.o strlcpy.o strtonum.o verrc.o
    OBJECTS+=$(COMPAT:%.o=compat/%.o)
endif
ifeq ($(UNAME_S),FreeBSD)
    CFLAGS+=-DHAVE_LOGIN_CAP_H
    LDFLAGS+=-lutil
endif
ifeq ($(UNAME_S),SunOS)
    SAFE_PATH?=/bin:/sbin:/usr/bin:/usr/sbin:$(PREFIX)/bin:$(PREFIX)/sbin
    GLOBAL_PATH?=/bin:/sbin:/usr/bin:/usr/sbin:$(PREFIX)/bin:$(PREFIX)/sbin
    CPPFLAGS+=-Icompat
    CFLAGS+=-DSOLARIS_PAM -DSAFE_PATH=\"$(SAFE_PATH)\" -DGLOBAL_PATH=\"$(GLOBAL_PATH)\"
    COMPAT=errc.o pm_pam_conv.o setresuid.o verrc.o
    OBJECTS+=$(COMPAT:%.o=compat/%.o)
endif

all: $(OBJECTS)
	$(CC) -o $(BIN) $(OBJECTS) $(LDFLAGS)

env.o: doas.h env.c

execvpe.o: doas.h execvpe.c

doas.o: doas.h doas.c parse.y

reallocarray.o: doas.h reallocarray.c

y.tab.o: parse.y
	$(YACC) parse.y
	$(CC) $(CPPFLAGS) $(CFLAGS) -c y.tab.c

install: $(BIN)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp $(BIN) $(DESTDIR)$(PREFIX)/bin/
	chmod 4755 $(DESTDIR)$(PREFIX)/bin/$(BIN)
	mkdir -p $(MANDIR)/man1
	cp doas.1 $(MANDIR)/man1/
	mkdir -p $(MANDIR)/man5
	cp doas.conf.5 $(MANDIR)/man5/

clean:
	rm -f $(BIN) $(OBJECTS) y.tab.c

