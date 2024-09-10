FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit systemd

SYSTEMD_SERVICE:${PN} = "pulseaudio.service"
SYSTEMD_AUTO_ENABLE:${PN}  = "enable"

SRC_URI:append = "\
    file://pulseaudio.service \
    file://load-unix-module.pa \
"

do_install:append() {
        install -d ${D}/${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/pulseaudio.service ${D}/${systemd_unitdir}/system
        install -d ${D}/${sysconfdir}/pulse/system.pa.d
        install -m 0644 ${WORKDIR}/load-unix-module.pa ${D}/${sysconfdir}/pulse/system.pa.d
}

FILES:${PN}:append = "${systemd_unitdir}/system/pulseaudio.service ${sysconfdir}/pulse/load-unix-module.pa"
