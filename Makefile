RELEASE=3.4

PACKAGE=pve-sheepdog
PKGREL=2
SDVER=0.9.2

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB=${PACKAGE}_${SDVER}-${PKGREL}_${ARCH}.deb

SDDIR=sheepdog-${SDVER}
SDSRC=${SDDIR}.tar.gz

all: ${DEB}

${DEB} deb: ${SDSRC}
	rm -rf ${SDDIR}
	tar xf ${SDSRC}
	mv ${SDDIR}/debian ${SDDIR}/debian.org
	cp -av debian ${SDDIR}/debian
	echo "git clone git://git.proxmox.com/git/pve-sheepdog.git\\ngit checkout ${GITVERSION}" > ${SDDIR}/debian/SOURCE
	cd ${SDDIR}; dpkg-buildpackage -rfakeroot -b -us -uc
	lintian -X copyright-file ${DEB}

.PHONY: download
${SDSRC} download:
	rm -rf ${SDDIR} sheepdog.git
	git clone git://github.com/sheepdog/sheepdog.git sheepdog.git
	cd sheepdog.git; git checkout -b local v${SDVER}_rc0
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

