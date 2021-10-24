PREFIX ?=	/usr
BINDIR ?=	${PREFIX}/bin
MANDIR ?=	${PREFIX}/share/man

all:

install:
	install -d "${DESTDIR}${BINDIR}" "${DESTDIR}${MANDIR}"/man1
	install -m 755 pns.sh "${DESTDIR}${BINDIR}"/pns
	install -m 644 pns.1 "${DESTDIR}${MANDIR}"/man1/pns.1

.PHONY: all install
