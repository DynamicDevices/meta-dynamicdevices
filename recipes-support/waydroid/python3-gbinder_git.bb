# Copyright (C) 2015 Khem Raj <raj.khem@gmail.com>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "Cython extension module for gbinder"
HOMEPAGE = "https://github.com/waydroid/gbinder-python"
LICENSE = "GPL-3.0-only"
SECTION = "devel/python"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

# Waydroid 1.6.3 requires gbinder-python >= 1.3.0. Version 1.3.1 retains
# the Cython 3 noexcept fixes required by the Scarthgap toolchain.
PV = "1.3.1+git${SRCPV}"
SRCREV = "86b8feba4cacd0952b010d1c3af6a29a0c146ced"
SRC_URI = "git://github.com/waydroid/gbinder-python.git;branch=main;protocol=https"

S = "${WORKDIR}/git"

DEPENDS = "libgbinder python3-cython-native libglibutil"

RDEPENDS:${PN}:class-native = ""
DEPENDS:append:class-native = " python-native "

inherit setuptools3 pkgconfig

BBCLASSEXTEND = "native"
