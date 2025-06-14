DESCRIPTION = "This is a Library of glib utilities. require for waydroid app."
HOMEPAGE = "https://waydro.id/"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = "file://LICENSE;md5=097b16a03e30548ee88ebcf6f7fbae97"

SRCREV = "2b1ea51c483df597f62c4b058b3d120b782836d1"

SRC_URI = "git://github.com/waydroid/libglibutil.git;protocol=https;branch=bullseye"
SRC_URI[sha256sum] = "3ca7c76c549d91ef516be68832917ba33545ea428957aa8635543451d70585b1"

S = "${WORKDIR}/git"
EXTRA_OECMAKE = ""
DEPENDS = "glib-2.0 "

inherit base pkgconfig

do_configure () {
    # Specify any needed configure commands here
    :
}

do_compile () {
    # You will almost certainly need to add additional arguments here
    oe_runmake
}

do_install () {
         oe_runmake install-dev DESTDIR=${D} SBINDIR=${sbindir} MANDIR=${mandir} INCLUDEDIR=${includedir}
}
