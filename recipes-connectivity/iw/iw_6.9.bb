SUMMARY = "nl80211 based CLI configuration utility for wireless devices with TWT support"
DESCRIPTION = "iw is a new nl80211 based CLI configuration utility for wireless devices. \
Version 6.9 includes Target Wake Time (TWT) support for WiFi 6 power optimization."
HOMEPAGE = "https://wireless.wiki.kernel.org/en/users/documentation/iw"
SECTION = "base"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://COPYING;md5=878618a5c4af25e9b93ef0be1a93f774"

DEPENDS = "libnl pkgconfig-native"

# Official release with TWT support
SRC_URI = "https://www.kernel.org/pub/software/network/iw/iw-${PV}.tar.xz"
SRC_URI[sha256sum] = "3f2db22ad41c675242b98ae3942dbf3112548c60a42ff739210f2de4e98e4894"

S = "${WORKDIR}/iw-${PV}"

# Ensure proper linking flags
TARGET_CC_ARCH += "${LDFLAGS}"

EXTRA_OEMAKE = "\
    'PREFIX=${prefix}' \
    'SBINDIR=${sbindir}' \
    'MANDIR=${mandir}' \
"

do_compile() {
    oe_runmake
}

do_install() {
    oe_runmake 'DESTDIR=${D}' 'PREFIX=${prefix}' install
}

# Package information
PACKAGES = "${PN} ${PN}-dbg ${PN}-doc"
FILES:${PN} = "${sbindir}/iw"
FILES:${PN}-doc = "${mandir}"

