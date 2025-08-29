FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Machine-specific device registration scripts
SRC_URI:append:imx8mm-jaguar-sentai = " file://imx8mm-jaguar-sentai/lmp-device-auto-register"
SRC_URI:append:imx8mm-jaguar-handheld = " file://imx8mm-jaguar-handheld/lmp-device-auto-register"
SRC_URI:append:imx93-jaguar-eink = " file://imx93-jaguar-eink/lmp-device-auto-register"

do_install:append() {
    # Install machine-specific device registration script if available
    if [ -f ${WORKDIR}/${MACHINE}/lmp-device-auto-register ]; then
        install -D -m 0755 ${WORKDIR}/${MACHINE}/lmp-device-auto-register ${D}${bindir}/lmp-device-auto-register
    fi
}
