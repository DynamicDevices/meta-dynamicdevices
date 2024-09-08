FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit systemd

SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-sentai = "load-pulseaudio-modules.service"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-sentai = "enable"

SRC_URI += "\
    file://load-pulseaudio-modules.service \
    file://load-pulseaudio-modules.sh \
"

do_install:append:imx8mm-jaguar-sentai() {
        install -D -m 0755 ${WORKDIR}/load-pulseaudio-modules.sh ${D}${bindir}/load-pulseaudio-modules.sh
        install -d ${D}/${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/load-pulseaudio-modules.service ${D}/${systemd_unitdir}/system/load-pulseaudio-modules.service
}

FILES:${PN}:imx8mm-jaguar-sentai += "${bindir}/load-pulseaudio-modules.sh"
