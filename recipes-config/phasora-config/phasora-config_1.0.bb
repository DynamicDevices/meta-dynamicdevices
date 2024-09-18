FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

DESCRIPTION = "Custom Image Configuration for Phasora"
LICENSE="CLOSED"

SRC_URI = "file://save-calibration.sh"

# For other customisations to final image see the image files in recipes-fsl/images

do_install() {
   # Install the calibration helper file
   install -d ${D}${bindir}
   install -m 0755 ${WORKDIR}/save-calibration.sh ${D}${bindir}
}

# Populate packages
FILES:${PN} = "${bindir}"

RDEPENDS:${PN} += "bash"
