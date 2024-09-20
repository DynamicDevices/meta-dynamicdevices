FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = "\
  file://iwlwifi-ty-a0-gf-a0-59.ucode \
"

do_install:append() {
    install -d  ${D}/${nonarch_base_libdir}/firmware
    install -m 0644 ${WORKDIR}/iwlwifi-ty-a0-gf-a0-59.ucode ${D}/${nonarch_base_libdir}/firmware/iwlwifi-ty-a0-gf-a0-59.ucode
}

FILES:${PN}-iwlwifi-ax210 += " \
       ${nonarch_base_libdir}/firmware/iwlwifi-ty-a0-gf-a0-59.ucode \
"

RPROVIDES:${PN} += "${PN}-iwlwifi-ax210"

INSANE_SKIP:${PN} += "ldflags"
