DESCRIPTION = "Run a full Android system in a container and provide Android applications on any GNU/Linux-based platform."
HOMEPAGE = "https://waydro.id/"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

SRCREV = "d8c700bbb8b7bd992b9fe9b43de8a2f3d8e8587f"

SRC_URI = "git://github.com/waydroid/waydroid.git;protocol=https;branch=main"
SRC_URI[sha256sum] = "c85bc0e4f44417c429d799008d3444e1045785e82f96efb2cddbd812b9633f61"

S = "${WORKDIR}/git"
EXTRA_OECMAKE = ""
DEPENDS += "python python3 python3-pip lxc python3-pkgconfig python3-pycairo python3-pygobject"
RDEPENDS:${PN} += "glib-2.0 libglibutil libgbinder gbinder-python"

do_configure () {
    # Specify any needed configure commands here
    :
}

do_compile () {
    # You will almost certainly need to add additional arguments here
	:
}

do_install () {
    oe_runmake install DESTDIR=${D} SBINDIR=${sbindir} MANDIR=${mandir} INCLUDEDIR=${includedir}	
    oe_runmake install_apparmor DESTDIR=${D} SBINDIR=${sbindir} MANDIR=${mandir} INCLUDEDIR=${includedir}	
}

FILES:${PN} = " \
  /usr/bin/* \
  /usr/lib/* \
  /usr/share/metainfo/* \
  /usr/share/applications/* \
  /usr/lib/waydroid/* \
  ${systemd_unitdir}/system/waydroid-container.service \
"
