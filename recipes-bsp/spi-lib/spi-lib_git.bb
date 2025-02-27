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

SRCBRANCH = "okan/new"
SRC_URI = "git://git@github.com/DynamicDevices/spi-lib.git;protocol=ssh;branch=${SRCBRANCH}"

# Modify these as desired
PV = "1.0+git${SRCPV}"
SRCREV = "809fea9a04ea37f9bef42dd708ca0a6cbea8eee2"

S = "${WORKDIR}/git"

inherit cmake

# Specify any options you want to pass to cmake using EXTRA_OECMAKE:
EXTRA_OECMAKE = ""

TARGET_CFLAGS += "-Wno-c++11-narrowing" 
