FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://01-disable-scan-in-progress-warning.patch"

inherit systemd

SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-sentai = "enable-wifi.service"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-sentai = "enable"

SRC_URI:append:imx8mm-jaguar-sentai = "\
    file://enable-wifi.sh \
    file://enable-wifi.service \
    file://99-ignore-uap.conf \
"

do_install:append:imx8mm-jaguar-sentai() {
    install -d ${D}/${bindir}
    install -D -m 0755 ${WORKDIR}/*.sh ${D}${bindir}
    install -d ${D}/${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/*.service ${D}/${systemd_unitdir}/system
    install -d ${D}${sysconfdir}/NetworkManager/conf.d
    install -D -m 0644 ${WORKDIR}/99-ignore-uap.conf ${D}${sysconfdir}/NetworkManager/conf.d/99-ignore-uap.conf
}

FILES:${PN}:imx8mm-jaguar-sentai += "${systemd_unitdir}/system/*.service ${bindir}/*.sh ${sysconfdir}/NetworkManager/conf.d/99-ignore-uap.conf"
