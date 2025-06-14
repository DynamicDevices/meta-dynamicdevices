DESCRIPTION = "This is Cython extension module for gbinder. require for waydroid app."
HOMEPAGE = "https://waydro.id/"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

SRCREV = "423dc366561c82515f4f2f46017535e7d81ce5b1"

SRC_URI = "git://github.com/waydroid/gbinder-python.git;protocol=https;branch=bullseye"
SRC_URI[sha256sum] = "32264ecef35e0aaa17a7c9024d9f9483ae1e505032dac16683ed1f87a126af50"
SRC_URI += "file://gbinder.c"


S = "${WORKDIR}/git"

EXTRA_OECMAKE = ""
DEPENDS += "python3-native python3 python3-pip python3-cython python-cython glib-2.0 libglibutil libgbinder "
RDEPENDS_${PN} += "python3 python3-pip python3-cython python-cython glib-2.0 libglibutil libgbinder "

inherit pkgconfig lib_package setuptools3

do_compile () {
    # You will almost certainly need to add additional arguments here
    cp ${WORKDIR}/gbinder.c ${WORKDIR}/build/
    python3 ${S}/setup.py build_ext --inplace
}

do_install () {
    #oe_runmake install-dev DESTDIR=${D} SBINDIR=${sbindir} MANDIR=${mandir} INCLUDEDIR=${includedir}
    install -d ${D}${libdir}
    mkdir -p ${D}${libdir}/python3.8/site-packages/
    cp ${WORKDIR}/build/gbinder.c* ${D}${libdir}/python3.8/site-packages/
    :	
}
