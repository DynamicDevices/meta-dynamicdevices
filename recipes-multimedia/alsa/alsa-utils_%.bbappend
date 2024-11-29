FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#
# NOTE: We need to fix the IDs of the playback and recording
#       drivers so they don't change on boot. So we do this
#       here. We blacklist the drivers so they don't automatically
#       load. Then we will load the drivers in the order we want
#       with the systemd service
#

inherit systemd

SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-sentai = "audio-driver.service"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-sentai = "enable"

SRC_URI:append:imx8mm-jaguar-sentai = "\
    file://blacklist-audio.conf \
    file://load-snd-aloop.conf \
    file://audio-driver.service \
    file://load-audio-drivers.sh \
"
 
do_install:append:imx8mm-jaguar-sentai() {
        install -d ${D}${sysconfdir}/modprobe.d
        install -D -m 0644 ${WORKDIR}/blacklist-audio.conf ${D}${sysconfdir}/modprobe.d/blacklist-audio.conf
        install -d ${D}${sysconfdir}/modules-load.d
        install -D -m 0644 ${WORKDIR}/load-snd-aloop.conf ${D}${sysconfdir}/modules-load.d/load-snd-aloop.conf
        install -D -m 0755 ${WORKDIR}/load-audio-drivers.sh ${D}${bindir}/load-audio-drivers.sh
        install -d ${D}${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/audio-driver.service ${D}${systemd_unitdir}/system/audio-driver.service
}
 
FILES:${PN}:imx8mm-jaguar-sentai += "${sysconfdir}/modprobe.d/blacklist-audio.conf ${sysconfdir}/modules-load.d/load-snd-aloop.conf"
FILES:${PN}:imx8mm-jaguar-sentai += "${systemd_unitdir}/system/audio-driver.service ${bindir}/load-audio-drivers.sh"
