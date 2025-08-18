FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
    # Remove ALSA state directory to prevent state file creation
    rm -rf ${D}${localstatedir}/lib/alsa
}
