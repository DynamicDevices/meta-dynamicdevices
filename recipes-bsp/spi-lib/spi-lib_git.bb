FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SUMMARY = "SPI library for radar presence detection"
DESCRIPTION = "A C++ library providing SPI communication interface for radar sensors \
and presence detection functionality with systemd service integration."
HOMEPAGE = "https://github.com/DynamicDevices/spi-lib"
SECTION = "libs"
AUTHOR = "Dynamic Devices Ltd"

LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=535d3a1b7f971b2e6581673c210e768c"

SRCBRANCH = "main"
SRC_URI = "git://git@github.com/DynamicDevices/spi-lib.git;protocol=ssh;branch=${SRCBRANCH} \
           file://radar-presence.service \
"

# Modify these as desired
PV = "1.0+git${SRCPV}"
SRCREV = "b9c1fc6be2bbcc486ff0ee3495b1f9a77cb1e4a5"

S = "${WORKDIR}/git"

inherit cmake

# TODO: Fix C++11 narrowing conversion warnings in source code
TARGET_CFLAGS += "-Wno-c++11-narrowing"

# QA Skip Justification: This is a development library that intentionally
# includes development dependencies and ELF files for radar sensor integration.
# These are required for the SPI communication interface functionality.
INSANE_SKIP = "dev-deps dev-elf"

inherit systemd

SYSTEMD_SERVICE:${PN} = "radar-presence.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install:append() {
  install -d ${D}${systemd_unitdir}/system
  install -m 0644 ${WORKDIR}/radar-presence.service ${D}${systemd_unitdir}/system/radar-presence.service
}
