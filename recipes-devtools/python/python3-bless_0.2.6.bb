# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

SUMMARY = "A Bluetooth Low Energy Server supplement to Bleak"
HOMEPAGE = "https://github.com/kevincar/bless"
# WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses - it is
# your responsibility to verify that the values are complete and correct.
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=c271c787dbb9f120530510c641990f11"

SRC_URI = "git://github.com/kevincar/bless.git;protocol=https;branch=master"

# Modify these as desired
PV = "0.2.6+git${SRCPV}"
SRCREV = "bd0bdf03825876d377bc016c07bc08b4b1c671d5"

S = "${WORKDIR}/git"

inherit setuptools3

# WARNING: the following rdepends are determined through basic analysis of the
# python sources, and might not be 100% accurate.
RDEPENDS:${PN} += "python3-asyncio python3-bleak python3-core python3-dbus-next python3-logging python3-netclient"

