FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SUMMARY = "Enable a USB serial terminal"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
	file://usb-terminal.service \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "usb-terminal.service"

do_install() {
	install -d ${D}${systemd_system_unitdir}
	install -m 0644 ${WORKDIR}/usb-terminal.service ${D}${systemd_system_unitdir}/
}
