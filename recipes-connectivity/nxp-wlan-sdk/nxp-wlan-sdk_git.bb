require nxp-wlan-sdk_git.inc

SUMMARY = "NXP Wi-Fi SDK"

inherit module-base

TARGET_CC_ARCH += "${LDFLAGS}"

do_compile () {
    oe_runmake build
}

do_install () {
    install -d ${D}${datadir}/nxp_wireless

    install -m 0755 script/load ${D}${datadir}/nxp_wireless
    install -m 0755 script/unload ${D}${datadir}/nxp_wireless
    install -m 0644 README ${D}${datadir}/nxp_wireless
}

FILES:${PN} = "${datadir}/nxp_wireless"

COMPATIBLE_MACHINE = "(imx-nxp-bsp)"

inherit systemd

SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-sentai = "enable-wifi.service"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-sentai = "enable"

SRC_URI:append:imx8mm-jaguar-sentai = "\
    file://enable-wifi.sh \
    file://enable-wifi.service \
"

do_install:append:imx8mm-jaguar-sentai() {
        install -d ${D}/${bindir}
        install -D -m 0755 ${WORKDIR}/*.sh ${D}${bindir}
        install -d ${D}/${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/*.service ${D}/${systemd_unitdir}/system
}

FILES:${PN}:imx8mm-jaguar-sentai += "${systemd_unitdir}/system/*.service ${bindir}/*.sh"

