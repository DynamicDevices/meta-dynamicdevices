FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

# WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses - it is
# your responsibility to verify that the values are complete and correct.
#
# The following license files were not able to be identified and are
# represented as "Unknown" below, you will need to check them yourself:
#   3rd_party/licenses.md
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=535d3a1b7f971b2e6581673c210e768c"

SRCBRANCH = "main"
SRC_URI = "git://git@github.com/DynamicDevices/spi-lib.git;protocol=ssh;branch=${SRCBRANCH} \
           file://radar-presence.service \
"

# Modify these as desired
PV = "1.0+git${SRCPV}"
SRCREV = "d465166267c58b583614d9c540837942c4d31498"

S = "${WORKDIR}/git"

inherit cmake

# Specify any options you want to pass to cmake using EXTRA_OECMAKE:
EXTRA_OECMAKE = ""

TARGET_CFLAGS += "-Wno-c++11-narrowing" 

INSANE_SKIP = "dev-deps dev-elf"

inherit systemd

SYSTEMD_SERVICE:${PN} = "radar-presence.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install:append() {
  install -d ${D}${systemd_unitdir}/system
  install -m 0644 ${WORKDIR}/radar-presence.service ${D}${systemd_unitdir}/system/radar-presence.service
}
