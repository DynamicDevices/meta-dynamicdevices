FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit systemd

SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-sentai = "pulse-audio-init.service"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-sentai = "enable"

SRC_URI += "\
    file://pulse-audio-init.sh \
    file://pulse-audio-init.service \
"

do_install:append:imx8mm-jaguar-sentai() {
        install -D -m 0755 ${WORKDIR}/pulse-audio-init.sh ${D}${bindir}/pulse-audio-init.sh
        install -d ${D}/${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/pulse-audio-init.service ${D}/${systemd_unitdir}/system
}

FILES:${PN}:imx8mm-jaguar-sentai += "${systemd_unitdir}/system/pulse-audio-init.service ${bindir}/pulse-audio-init.sh"


