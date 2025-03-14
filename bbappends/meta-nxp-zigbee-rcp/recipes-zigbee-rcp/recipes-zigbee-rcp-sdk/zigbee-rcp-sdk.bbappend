FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit systemd

SRC_URI:append:imx8mm-jaguar-sentai = " file://zb_mux.sh"

do_install:append:imx8mm-jaguar-sentai() {
    install -d ${D}${sbindir}
    install -m 0744 ${S}/bin/zb_mux ${D}${sbindir}
    install -m 0744 ${S}/zb_mux.sh ${D}${sbindir}
    install -m 0744 ${S}/scripts/*.sh ${D}${sbindir}
    install -d ${D}${sysconfdir}/default
    install -m 0644 ${S}/scripts/ota-client.cfg ${D}${sysconfdir}/default
}

# Not sure if the apps are installed with the SDK or the separate APP recipe ???
# The service IS installed by the SDK but...?
SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-sentai = "zb_app.service"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-sentai = "enable"

RDEPENDS:${PN}:imx8mm-jaguar-sentai += " bash"
