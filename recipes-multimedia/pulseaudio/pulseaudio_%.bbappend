FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit systemd

SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-sentai = "pulseaudio.service"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-sentai = "enable"

SRC_URI += "\
    file://pulseaudio.service \
"

do_install:append:imx8mm-jaguar-sentai() {
        install -d ${D}/${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/pulseaudio.service ${D}/${systemd_unitdir}/system
}

FILES:${PN}:imx8mm-jaguar-sentai += "${systemd_unitdir}/system/pulseaudio.service"


