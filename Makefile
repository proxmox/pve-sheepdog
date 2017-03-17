RELEASE=4.2

PACKAGE=pve-sheepdog
PKGREL=1
SDVER=1.0.0

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
	git clone git://github.com/sheepdog/sheepdog.git -b v1.0 sheepdog.git
	cd sheepdog.git; git archive --format=tar.gz -o ../${SDSRC}.tmp v1.0 --prefix=${SDDIR}/
	mv ${SDSRC}.tmp ${SDSRC}

.PHONY: upload
upload: ${DEB}
	tar cf - ${DEB} | ssh repoman@repo.proxmox.com -- upload --product pve --dist jessie

clean:
distclean: clean
	rm -rf sheepdog.git

.PHONY: clean
clean:
	rm -rf *~ debian/*~ *.deb *.changes *.dsc ${SDDIR} ${SDSRC}.tmp

.PHONY: dinstall
dinstall: ${DEB}
	dpkg -i ${DEB}

