FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DESCRIPTION = "udev rules for Freescale i.MX SOC based Jaguar boards"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI:append = " file://20-jaguar.rules"

S = "${WORKDIR}"

do_install () {
	install -d ${D}${sysconfdir}/udev/rules.d
	install -m 0644 ${WORKDIR}/20-jaguar.rules ${D}${sysconfdir}/udev/rules.d/
}
