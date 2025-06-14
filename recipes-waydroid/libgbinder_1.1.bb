DESCRIPTION = "This is a Library of GLib-style interface to binder (Android IPC mechanism). require for waydroid app."
HOMEPAGE = "https://waydro.id/"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = "file://LICENSE;md5=141fd1196873d8eda11b63e24faf2739"

SRCREV = "848aef690a21caaed84355d302d1ee86e6d40a58"

SRC_URI = "git://github.com/waydroid/libgbinder.git;protocol=https;branch=bullseye"
SRC_URI[sha256sum] = "fa264ad1eeb89a97922c3287f8e10b2a03faece3a7db0433527453df6fbd4cb1"

S = "${WORKDIR}/git"
EXTRA_OECMAKE = ""
DEPENDS = "glib-2.0 libglibutil"

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
