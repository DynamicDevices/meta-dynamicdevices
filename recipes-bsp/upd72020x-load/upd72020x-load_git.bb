# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

# Unable to find any files that looked like license statements. Check the accompanying
# documentation and source headers and set LICENSE and LIC_FILES_CHKSUM accordingly.
#
# NOTE: LICENSE is being set to "CLOSED" to allow you to at least start building - if
# this is not accurate with respect to the licensing of the software being built (it
# will not be in most cases) you must specify the correct value before using this
# recipe for anything other than initial testing/development!
DESCRIPTION = "Firmware loader for Renesas uPD72020x USB 3.0 chipsets for Linux"
HOMEPAGE = "https://github.com/denisandroid/uPD72020x-Firmware"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd

SYSTEMD_SERVICE:${PN} = "upd72020x-fwload.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

SRC_URI = "git://github.com/markusj/upd72020x-load;protocol=https;branch=master \
           file://K2026.mem \
"

# Modify these as desired
PV = "1.0+git${SRCPV}"
SRCREV = "62689b2721c330823bec3680bc7ae9569819d529"

S = "${WORKDIR}/git"

do_configure() {
}

do_compile () {
	oe_runmake
}

do_install () {
  install -d ${D}${sbindir}
  install -m 755 ${B}/upd72020x-load ${D}${sbindir}
  install -m 755 ${B}/upd72020x-check-and-init ${D}${sbindir}
  install -d ${D}${libdir}/firmware/renesas
  install -m 0644 ${WORKDIR}/K2026.mem ${D}${libdir}/firmware/renesas/K2026.mem
  install -d ${D}${systemd_unitdir}/system
  install -m 0644 ${S}/systemd/upd72020x-fwload.service ${D}${systemd_unitdir}/system/upd72020x-fwload.service
}

FILES:${PN} += "${libdir}/firmware/renesas/K2026.mem"
RDEPENDS:${PN} = "bash"
