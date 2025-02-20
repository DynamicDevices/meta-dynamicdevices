FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LICENSE = "GPL-3.0-or-later"
LIC_FILES_CHKSUM ?= "file://${COMMON_LICENSE_DIR}/GPL-3.0-or-later;md5=1c76c4cc354acaac30ed4d5eefea7245"

inherit systemd

SYSTEMD_SERVICE:${PN} = "setup-default-connections.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

SRC_URI = "file://setup-default-connections.sh \
           file://setup-default-connections.service \
"

do_install() {
  install -d ${D}${bindir}
  install -m 755 ${WORKDIR}/setup-default-connections.sh ${D}${bindir}
  install -d ${D}${systemd_unitdir}/system 	
  install -m 0644 ${WORKDIR}/setup-default-connections.service ${D}${systemd_unitdir}/system/setup-default-connections.service
}

FILES:${PN} = "${bindir}/setup-default-connections.sh ${system_unitdir}/system/setup-default-connections.service"

