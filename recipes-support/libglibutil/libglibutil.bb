# Copyright (c) 2019 Christophe Chapuis <chris.chapuis@gmail.com>

DESCRIPTION = "Library of glib utilities."
LICENSE = "BSD-3-Clause"
SECTION = "webos/support"
LIC_FILES_CHKSUM = "file://LICENSE;md5=d06f24f367f70ea228818e7442fa90c7"

DEPENDS = "glib-2.0"

inherit pkgconfig

SRC_URI = "git://github.com/sailfishos/libglibutil.git;protocol=https;nobranch=1"
S = "${WORKDIR}/git"

# Exact dependency revision used by the validated Android 16 host runtime.
PV = "1.0.82"
SRCREV = "cccc4aa8f1745096f6feb66da7883b35055d9423"

EXTRA_OEMAKE = "KEEP_SYMBOLS=1"
PARALLEL_MAKE = ""

do_install() {
    make install DESTDIR=${D}
    make install-dev DESTDIR=${D}
}
