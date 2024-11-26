# Copyright 2021 NXP
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DESCRIPTION = "NXP Audio Front End (AFE) for incorporating Voice Assistants"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=7bdef19938f3503cfc4c586461f99012"

PV = "1.0+git${SRCPV}" 

SRCBRANCH = "MM_04.08.03_2312_L6.6.y"
NXPAFE_SRC ?= "git://github.com/nxp-imx/nxp-afe.git;protocol=https"
SRC_URI = " \
    ${NXPAFE_SRC};branch=${SRCBRANCH} \
    file://nxp-afe.service \
"

SRCREV = "3730d21c1b93016f14befcc78f8b11e01d443e48" 

S = "${WORKDIR}/git"

inherit systemd

DEPENDS += "alsa-lib"
RDEPENDS:${PN} = "alsa-state alsa-lib"

TARGET_CC_ARCH += "${LDFLAGS}"

do_compile() {
        oe_runmake clean
        oe_runmake all
}

do_install() {
        install -d ${D}${libdir}/nxp-afe
        install -d ${D}/unit_tests/nxp-afe
        install -m 0644 ${WORKDIR}/deploy_afe/*.so.1.0 ${D}${libdir}/nxp-afe
        ln -sf -r ${D}${libdir}/nxp-afe/libdummyimpl.so.1.0 ${D}${libdir}/nxp-afe/libdummyimpl.so
        install -d ${D}${sbindir}
        install -m 0755 ${WORKDIR}/deploy_afe/afe ${D}${sbindir}/afe
        install -d ${D}/${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/nxp-afe.service ${D}/${systemd_unitdir}/system/nxp-afe.service
}

FILES:${PN} += "/unit_tests ${sbindir} ${systemd_unitdir}/system"
INSANE_SKIP:${PN} += "dev-so"

SYSTEMD_SERVICE:${PN} = "nxp-afe.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"
