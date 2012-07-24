RELEASE=2.1

PACKAGE=pve-sheepdog
PKGREL=7
SDVER=0.4.0

DEB=${PACKAGE}_${SDVER}-${PKGREL}_amd64.deb

SDDIR=sheepdog-${SDVER}
SDSRC=${SDDIR}.tar.gz

all: ${DEB}

${DEB} deb: ${SDSRC}
	rm -rf ${SDDIR}
	tar xf ${SDSRC}
	cp -av debian ${SDDIR}/debian
	cd ${SDDIR}; dpkg-buildpackage -rfakeroot -b -us -uc
	lintian ${DEB}

.PHONY: download
${SDSRC} download:
	rm -rf ${SDDIR} sheepdog.git
	git clone git://github.com/collie/sheepdog.git sheepdog.git
	#cd sheepdog.git; git checkout -b local v${SDVER}
	rsync -a --exclude .git --exclude .gitignore sheepdog.git/ ${SDDIR} 
	tar czf ${SDSRC}.tmp  ${SDDIR}
	rm -rf ${SDDIR}
	mv ${SDSRC}.tmp ${SDSRC}

.PHONY: upload
upload: ${DEB}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/pve-sheepdog*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEB} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

clean:
distclean: clean
	rm -rf sheepdog.git

.PHONY: clean
clean:
	rm -rf *~ debian/*~ *.deb *.changes *.dsc ${SDDIR} ${SDSRC}.tmp

.PHONY: dinstall
dinstall: ${DEB}
	dpkg -i ${DEB}

