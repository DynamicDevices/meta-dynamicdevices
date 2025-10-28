FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit systemd

SRC_URI:append:imx8mm-jaguar-sentai = " \
  file://zb_mux.sh \
  file://zb_config.service \
  file://zb_app.env \
"

do_install:append:imx8mm-jaguar-sentai() {
    install -d ${D}${sbindir}
    install -m 0744 ${S}/bin/zb_mux ${D}${sbindir}
    install -m 0744 ${S}/zb_mux.sh ${D}${sbindir}
    install -m 0744 ${S}/scripts/*.sh ${D}${sbindir}
    
    # Install all available Zigbee applications to /usr/bin for easier access
    install -d ${D}${bindir}
    for app in ${S}/bin/*; do
        if [ -f "$app" ] && [ -x "$app" ] && [ "$(basename "$app")" != "zb_mux" ]; then
            install -m 0755 "$app" ${D}${bindir}
        fi
    done
    
    install -d ${D}/etc/default
    install -m 0644 ${S}/zb_app.env ${D}/etc/default
    install -m 0644 ${S}/scripts/ota-client.cfg ${D}/etc/default
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/zb_config.service ${D}${systemd_unitdir}/system/zb_config.service
    install -d ${D}${localstatedir}/zboss/ota-server-files
}

# Not sure if the apps are installed with the SDK or the separate APP recipe ???
# The service IS installed by the SDK but...?
SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-sentai = "zb_app.service"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-sentai = "enable"

RDEPENDS:${PN}:imx8mm-jaguar-sentai += " bash"

# Include /usr/bin in the package files for Zigbee applications
FILES:${PN}:append:imx8mm-jaguar-sentai = " ${bindir}/*"
