FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://zb_mux.sh"

do_install:append() {
    install -d ${D}${sbindir}
    install -m 0744 ${S}/bin/zb_mux ${D}${sbindir}
    install -m 0744 ${S}/zb_mux.sh ${D}${sbindir}
}
