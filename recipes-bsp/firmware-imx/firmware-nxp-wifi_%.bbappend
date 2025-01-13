
do_install:append() {
    sed -i 's/ps_mode=1/ps_mode=0/g' ${D}${nonarch_base_libdir}/firmware/nxp/wifi_mod_para.conf
}
