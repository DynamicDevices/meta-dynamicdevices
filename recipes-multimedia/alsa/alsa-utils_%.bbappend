FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#
# NOTE: We need to fix the IDs of the playback and recording
#       drivers so they don't change on boot. So we do this
#       here and then later on will manually load the drivers
#       in order
#

SRC_URI += "\
    file://blacklist-audio.conf \
"

do_install:append:imx8mm-jaguar-sentai() {
        install -D -m 0644 ${WORKDIR}/blacklist-audio.conf ${D}${sysconfdir}/modprobe.d/blacklist-audio.conf
}

FILES:alsa-utils:imx8mm-jaguar-sentai += "${sysconfdir}/modprobe.d/blacklist-audio.conf"
