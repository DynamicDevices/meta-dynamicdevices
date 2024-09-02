FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#
# NOTE: We need to fix the IDs of the playback and recording
#       drivers so they don't change on boot. So we do this
#       here and then will load the drivers in order with the
#       systemd service
#

SYSTEMD_AUTO_ENABLE = "enable"
SYSTEMD_SERVICE:${PN} = "audio-driver.service"

SRC_URI += "\
    file://blacklist-audio.conf \
    file://audio-driver.service \
    file://load-audio-drivers.sh \
"

do_install:append:imx8mm-jaguar-sentai() {
        install -D -m 0644 ${WORKDIR}/blacklist-audio.conf ${D}${sysconfdir}/modprobe.d/blacklist-audio.conf
        install -D -m 0755 ${WORKDIR}/load-audio-drivers.sh ${D}${bindir}/load-audio-drivers.sh
        install -d ${D}/${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/audio-driver.service ${D}/${systemd_unitdir}/system
}

FILES:${PN}:imx8mm-jaguar-sentai += "${sysconfdir}/modprobe.d/blacklist-audio.conf"
FILES:${PN}:imx8mm-jaguar-sentai += "${systemd_unitdir}/system/audio-driver.service ${bindir}/load-audio-drivers.sh"
