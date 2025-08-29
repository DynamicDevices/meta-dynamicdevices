SUMMARY = "Boot profiling tools and configuration for Dynamic Devices boards"
DESCRIPTION = "Comprehensive boot time analysis including U-Boot, kernel, and systemd profiling"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://boot-analysis.sh \
    file://boot-profiling.service \
    file://profile-boot.sh \
"

S = "${WORKDIR}"

RDEPENDS:${PN} = "bash systemd"

inherit systemd

SYSTEMD_SERVICE:${PN} = "boot-profiling.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    # Install boot analysis scripts
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/boot-analysis.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/profile-boot.sh ${D}${bindir}/
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/boot-profiling.service ${D}${systemd_system_unitdir}/
    
    # Create log directory
    install -d ${D}${localstatedir}/log/boot-profiling
}

FILES:${PN} += " \
    ${bindir}/boot-analysis.sh \
    ${bindir}/profile-boot.sh \
    ${systemd_system_unitdir}/boot-profiling.service \
    ${localstatedir}/log/boot-profiling \
"
