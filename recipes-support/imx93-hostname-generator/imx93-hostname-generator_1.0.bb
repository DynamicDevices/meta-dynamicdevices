SUMMARY = "Custom hostname generator for i.MX93 Jaguar E-Ink board"
DESCRIPTION = "Generates unique hostname based on hardware identifiers since OCOTP driver doesn't support i.MX93"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://generate-hostname.sh \
    file://imx93-hostname-generator.service \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "imx93-hostname-generator.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    # Install the hostname generation script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/generate-hostname.sh ${D}${bindir}/generate-hostname.sh
    
    # Install systemd service
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/imx93-hostname-generator.service ${D}${systemd_unitdir}/system/
}

FILES:${PN} += " \
    ${bindir}/generate-hostname.sh \
    ${systemd_unitdir}/system/imx93-hostname-generator.service \
"

RDEPENDS:${PN} = "bash"
