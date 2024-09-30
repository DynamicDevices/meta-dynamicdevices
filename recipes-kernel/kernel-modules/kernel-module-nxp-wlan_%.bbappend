FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#SRC_URI += "file://01-disable-scan-in-progress-warning.patch"

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
