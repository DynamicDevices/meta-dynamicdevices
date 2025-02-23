FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LICENSE = "GPL-3.0-or-later"
LIC_FILES_CHKSUM ?= "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

inherit systemd

SYSTEMD_SERVICE:${PN} = "board-init.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

SRC_URI = "file://board-init.sh \
           file://board-init.service \
"

SRC_URI:append:imx8mm-jaguar-sentai = "file://leds-proof-of-life.sh"

do_install() {
  install -d ${D}${bindir}
  install -m 755 ${WORKDIR}/*.sh ${D}${bindir}
  install -d ${D}${systemd_unitdir}/system 	
  install -m 0644 ${WORKDIR}/board-init.service ${D}${systemd_unitdir}/system/board-init.service
}

