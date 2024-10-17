FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:imx8mm-jaguar-sentai += "file://zb_mux.sh"

do_install:append:imx8mm-jaguar-sentai() {
    install -d ${D}${sbindir}
    install -m 0744 ${S}/bin/zb_mux ${D}${sbindir}
    install -m 0744 ${S}/zb_mux.sh ${D}${sbindir}
}
