FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
    file://alsa-base.conf \
"

do_install:append:imx8mm-jaguar-sentai() {
        install -D -m 0644 ${WORKDIR}/alsa-base.conf ${D}${sysconfdir}/alsa-base.conf
}

FILES:alsa-utils:imx8mm-jaguar-sentai += "${sysconfdir}/alsa-base.conf"
