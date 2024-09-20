FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:imx8mm-jaguar-phasora = "\
  file://iwlwifi-ty-a0-gf-a0-59.ucode \
"

do_install:append:imx8mm-jaguar-phasora() {
    install -d  ${D}/${nonarch_base_libdir}/firmware
    install -m 0644 ${WORKDIR}/iwlwifi-ty-a0-gf-a0-59.ucode ${D}/${nonarch_base_libdir}/firmware/iwlwifi-ty-a0-gf-a0-59.ucode
}

FILES:${PN}-iwlwifi-ty += " \
       ${nonarch_base_libdir}/firmware/iwlwifi-ty-a0-gf-a0-59.ucode \
"
