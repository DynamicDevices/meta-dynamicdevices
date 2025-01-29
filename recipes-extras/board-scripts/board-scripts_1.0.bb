FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM ?= "file://${COMMON_LICENSE_DIR}/GPL-3.0-only;md5=c79ff39f19dfec6d293b95dea7b07891"

SRC_URI:append = " \
  file://board-info.sh \
  file://test-leds-hb.sh \
  file://test-leds-rc.sh \
  file://set-fio-passwd.sh \
"

SRC_URI:append:imx8mm-jaguar-sentai = " \
  file://test-audio-hw.sh \
  file://dtmf-182846.wav \
  file://board-testing-now-starting-up.wav \
  file://tests-all-completed.wav \
  file://test-audio-play-and-record.sh \
  file://AudioTest-Microphone-One.mp3 \
  file://AudioTest-Microphone-Two.mp3 \
  file://AudioTest-Recording-Will-Now-Play-Back.mp3 \
  file://AudioTest-Recording-Should-Have-Played.mp3 \
"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/*.sh ${D}${sbindir}
}

do_install:append:imx8mm-jaguar-sentai() {
    install -d ${D}${datadir}/${PN}
    install -m 0755 ${WORKDIR}/*.wav ${D}${datadir}/${PN}
    install -m 0755 ${WORKDIR}/*.mp3 ${D}${datadir}/${PN}
}

RDEPENDS:${PN}:imx8mm-jaguar-sentai = "dtmf2num"
