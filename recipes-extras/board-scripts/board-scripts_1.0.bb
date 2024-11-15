FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM ?= "file://${COMMON_LICENSE_DIR}/GPL-3.0-only;md5=c79ff39f19dfec6d293b95dea7b07891"

SRC_URI:append = " \
  file://board-info.sh \
  file://test-leds-hb.sh \
  file://test-leds-rc.sh \
  file://set-fio-passwd.sh \
  file://test-audio-hw.sh \
  file://dtmf-1234.wav \
"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/*.sh ${D}${sbindir}
    install -d ${D}${datadir}/${PN}
    install -m 0755 ${WORKDIR}/*.wav ${D}${datadir}/${PN}
}


