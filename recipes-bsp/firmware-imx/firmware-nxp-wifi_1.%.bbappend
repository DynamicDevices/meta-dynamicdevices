FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#do_install:append() {
#    sed -i 's/ps_mode=1/ps_mode=2/g' ${D}${nonarch_base_libdir}/firmware/nxp/wifi_mod_para.conf
#    sed -i 's/auto_ds=1/auto_ds=2/g' ${D}${nonarch_base_libdir}/firmware/nxp/wifi_mod_para.conf
#}

#SRC_URI:append = "\
#    file://wifi-disable-power-saving.conf \
#"

#do_install:append() {
#    sed -i 's/ps_mode=1/ps_mode=0/g' ${D}${nonarch_base_libdir}/firmware/nxp/wifi_mod_para.conf
#    install -d ${D}${sysconfdir}/modprobe.d
#    install -D -m 0644 ${WORKDIR}/wifi-disable-power-saving.conf ${D}${sysconfdir}/modprobe.d/wifi-disable-power-saving.conf
#}

#FILES:${PN} += "${sysconfdir}/modprobe.d/wifi-disable-power-saving.conf"

# Only apply NetworkManager configuration for Dynamic Devices machines
SRC_URI:append:imx8mm-jaguar-sentai = "\
    file://99-ignore-uap.conf \
"
SRC_URI:append:imx8mm-jaguar-inst = "\
    file://99-ignore-uap.conf \
"
SRC_URI:append:imx8mm-jaguar-handheld = "\
    file://99-ignore-uap.conf \
"
SRC_URI:append:imx8mm-jaguar-phasora = "\
    file://99-ignore-uap.conf \
"
SRC_URI:append:imx93-jaguar-eink = "\
    file://99-ignore-uap.conf \
"

do_install:append() {
    install -d ${D}${sysconfdir}/NetworkManager/conf.d
    install -D -m 0644 ${WORKDIR}/99-ignore-uap.conf ${D}${sysconfdir}/NetworkManager/conf.d/99-ignore-uap.conf
}

FILES:${PN} += "${sysconfdir}/NetworkManager/conf.d/99-ignore-uap.conf"
