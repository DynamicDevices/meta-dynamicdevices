FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
    sed -i 's/ps_mode=1/ps_mode=2/g' ${D}${nonarch_base_libdir}/firmware/nxp/wifi_mod_para.conf
    sed -i 's/auto_ds=1/auto_ds=2/g' ${D}${nonarch_base_libdir}/firmware/nxp/wifi_mod_para.conf
}

SRC_URI:append = "\
    file://wifi-disable-power-saving.conf \
"

do_install:append() {
        install -d ${D}${sysconfdir}/modprobe.d
        install -D -m 0644 ${WORKDIR}/wifi-disable-power-saving.conf ${D}${sysconfdir}/modprobe.d/wifi-disable-power-saving.conf
}

FILES:${PN} += "${sysconfdir}/modprobe.d/wifi-disable-power-saving.conf"
