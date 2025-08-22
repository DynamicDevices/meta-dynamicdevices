SUMMARY = "E-ink Board Power Management"
DESCRIPTION = "Suspend/resume scripts optimized for the e-ink board low power operation"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://eink-suspend.sh \
    file://eink-resume.sh \
    file://eink-suspend.service \
    file://eink-resume.service \
    file://eink-power-config.sh \
    file://eink-power-config.service \
"

S = "${WORKDIR}"

RDEPENDS:${PN} = "bash iw wireless-tools"

inherit systemd

SYSTEMD_SERVICE:${PN} = "eink-suspend.service eink-resume.service eink-power-config.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # Install systemd services
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/eink-suspend.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/eink-resume.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/eink-power-config.service ${D}${systemd_system_unitdir}/

    # Install scripts
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/eink-suspend.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/eink-resume.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/eink-power-config.sh ${D}${bindir}/
}

FILES:${PN} = " \
    ${systemd_system_unitdir}/eink-suspend.service \
    ${systemd_system_unitdir}/eink-resume.service \
    ${systemd_system_unitdir}/eink-power-config.service \
    ${bindir}/eink-suspend.sh \
    ${bindir}/eink-resume.sh \
    ${bindir}/eink-power-config.sh \
"
