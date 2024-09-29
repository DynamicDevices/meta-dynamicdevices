
DESCRIPTION = "Board CE marking testing services and scripts"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LICENSE = "GPL-3.0-or-later"
LIC_FILES_CHKSUM ?= "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

#
# NOTE: We need to fix the IDs of the playback and recording
#       drivers so they don't change on boot. So we do this
#       here. We blacklist the drivers so they don't automatically
#       load. Then we will load the drivers in the order we want
#       with the systemd service
#

inherit systemd

SYSTEMD_SERVICE:imx8mm-jaguar-sentai = "ce-audio-test.service ce-led-test.service ce-mic-test.service ce-modem-test.service ce-wifi-bt-test.service ce-iperf3-test.service ce-radar-test.service"

SRC_URI:append:imx8mm-jaguar-sentai = "\
    file://ce-audio-test.service \
    file://ce-led-test.service \
    file://ce-mic-test.service \
    file://ce-modem-test.service \
    file://ce-wifi-bt-test.service \
    file://ce-iperf3-test.service \
    file://ce-radar-test.service \
    file://ce-audio-test.sh \
    file://ce-iperf3-test.sh \
    file://ce-led-test.sh \
    file://ce-mic-test.sh \
    file://ce-modem-test.sh \
    file://ce-radar-test.sh \
    file://ce-wifi-bt-test.sh \
    file://PinkPanther60.wav \
    file://ce-modem-pwrdwn.sh \
"

do_install:append:imx8mm-jaguar-sentai() {
        install -d ${D}/${datadir}/ce-testing
        install -D -m 0755 ${WORKDIR}/*.wav ${D}${datadir}/ce-testing
        install -d ${D}/${bindir}
        install -D -m 0755 ${WORKDIR}/*.sh ${D}${bindir}
        install -d ${D}/${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/*.service ${D}/${systemd_unitdir}/system
}

FILES:${PN}:imx8mm-jaguar-sentai += "${systemd_unitdir}/system/*.service ${bindir}/*.sh ${datadir}/ce-testing/*"

# NOTE: Should check machine features really e.g. for radar and other hardware support
RDEPENDS:${PN}:imx8mm-jaguar-sentai += " iperf3 spi-lib"
