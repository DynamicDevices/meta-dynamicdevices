# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

SUMMARY = "A python wrapper library for the network-manager cli client"
HOMEPAGE = "https://github.com/ushiboy/nmcli"
# WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses - it is
# your responsibility to verify that the values are complete and correct.
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=abb3664cf5202870a40a1272a6b2e0d6"

SRC_URI = "git://github.com/ushiboy/nmcli.git;protocol=https;branch=main"

# Modify these as desired
PV = "1.4.0+git${SRCPV}"
SRCREV = "8ef42464d2895b252f8ba32530dab055609b5a4f"

S = "${WORKDIR}/git"

inherit setuptools3

# WARNING: the following rdepends are determined through basic analysis of the
# python sources, and might not be 100% accurate.
RDEPENDS:${PN} += "python3-core python3-profile"
