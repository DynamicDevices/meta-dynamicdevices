# Copyright (C) 2015 Khem Raj <raj.khem@gmail.com>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "Cython extension module for gbinder"
HOMEPAGE = "https://github.com/waydroid/gbinder-python"
LICENSE = "GPL-3.0-only"
SECTION = "devel/python"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

# 1.1.1 + old Cython fails on Scarthgap (Python 3.12 / Cython 3.x). bullseye @ 4d8cb8f+
# adds explicit noexcept for Cython 3; 1.1.2 is current bullseye tip.
PV = "1.1.2+git${SRCPV}"
SRCREV = "5089d76d4cd958cedda0028ffd752c25508dd382"
SRC_URI = "git://github.com/waydroid/gbinder-python.git;branch=bullseye;protocol=https \
           file://0001-setup.py-Migrate-away-from-deprecated-distutils.core.patch \
"

S = "${WORKDIR}/git"

DEPENDS = "libgbinder python3-cython-native libglibutil"

RDEPENDS:${PN}:class-native = ""
DEPENDS:append:class-native = " python-native "

SETUPTOOLS_BUILD_ARGS = "sdist --cython"

inherit setuptools3 pkgconfig

BBCLASSEXTEND = "native"

