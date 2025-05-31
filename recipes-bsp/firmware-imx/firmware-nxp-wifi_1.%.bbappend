FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = "\
    file://wifi-disable-power-saving.conf \
    file://does-not-exist.conf \
"

do_install:append() {
    sed -i 's/ps_mode=1/ps_mode=0/g' ${D}${nonarch_base_libdir}/firmware/nxp/wifi_mod_para.conf
    install -d ${D}${sysconfdir}/modprobe.d
    install -D -m 0644 ${WORKDIR}/wifi-disable-power-saving.conf ${D}${sysconfdir}/modprobe.d/wifi-disable-power-saving.conf
}

FILES:${PN} += "${sysconfdir}/modprobe.d/wifi-disable-power-saving.conf"
