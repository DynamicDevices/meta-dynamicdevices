FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://01-disable-scan-in-progress-warning.patch"

# Disable scan debug messages for imx93-jaguar-eink to reduce kernel message spam
# Note: Using sed in do_configure instead of patch due to line number variations

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

# Add UAP ignore configuration for imx93-jaguar-eink
SRC_URI:append:imx93-jaguar-eink = " file://99-ignore-uap.conf"

do_install:append:imx93-jaguar-eink() {
    install -d ${D}${sysconfdir}/NetworkManager/conf.d
    install -D -m 0644 ${WORKDIR}/99-ignore-uap.conf ${D}${sysconfdir}/NetworkManager/conf.d/99-ignore-uap.conf
}

FILES:${PN}:imx93-jaguar-eink += "${sysconfdir}/NetworkManager/conf.d/99-ignore-uap.conf"

# Disable scan debug messages for imx93-jaguar-eink using sed during configure
do_configure:append:imx93-jaguar-eink() {
    # Comment out the START SCAN debug message
    sed -i 's/PRINTM(MINFO, "wlan: %s START SCAN\\n", priv->netdev->name);/\/\* PRINTM(MINFO, "wlan: %s START SCAN\\n", priv->netdev->name); \*\//' ${S}/mlinux/moal_main.c
    
    # Comment out the SCAN COMPLETED debug message in moal_scan.c if it exists
    if [ -f ${S}/mlinux/moal_scan.c ]; then
        sed -i 's/PRINTM(MINFO, "SCAN COMPLETED: scanned AP count=%d\\n",/\/\* PRINTM(MINFO, "SCAN COMPLETED: scanned AP count=%d\\n",/' ${S}/mlinux/moal_scan.c
        sed -i 's/scan_resp->num_in_scan_table);/scan_resp->num_in_scan_table); \*\//' ${S}/mlinux/moal_scan.c
    fi
}
