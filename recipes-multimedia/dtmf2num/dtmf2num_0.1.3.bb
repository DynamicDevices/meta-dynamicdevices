FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=49d88880cc0e7bfa08a569bd59daf595"

SRC_URI = "git://github.com/DynamicDevices/dtmf2num.git;protocol=https;branch=main"

SRCREV = "80b0b249d4656a217645346be84bff64460cf7ab"

S = "${WORKDIR}/git"

do_compile () {
    oe_runmake
}

do_install () {
  install -m 755 -d ${D}${bindir}
  install -m 755 ${S}/dtmf2num ${D}${bindir}/dtmf2num
}

