RELEASE=2.1

PACKAGE=pve-sheepdog
PKGREL=1
SDVER=0.3.0

DEB=${PACKAGE}_${SDVER}-${PKGREL}_amd64.deb

SDDIR=sheepdog-${SDVER}
SDSRC=${SDDIR}.tar.gz

all: ${DEB}

${DEB} deb: ${SDSRC}
	rm -rf ${SDDIR}
	tar xf ${SDSRC}
	cp -av debian ${SDDIR}/debian
	cd ${SDDIR}; dpkg-buildpackage -rfakeroot -b -us -uc
	lintian --suppress-tags possible-gpl-code-linked-with-openssl ${DEB}

.PHONY: download
${SDSRC} download:
	rm -rf ${SDDIR} sheepdog.git
	git clone git://github.com/collie/sheepdog.git -b for-0.4.0 sheepdog.git
	rsync -a --exclude .git --exclude .gitignore sheepdog.git/ ${SDDIR} 
	tar czf ${SDSRC}.tmp  ${SDDIR}
	rm -rf ${SDDIR}
	mv ${SDSRC}.tmp ${SDSRC}

clean:
distclean: clean
	rm -rf sheepdog.git

.PHONY: clean
clean:
	rm -rf *~ debian/*~ *.deb *.changes *.dsc ${SDDIR} ${SDSRC}.tmp

.PHONY: dinstall
dinstall: ${DEB}
	dpkg -i ${DEB}

