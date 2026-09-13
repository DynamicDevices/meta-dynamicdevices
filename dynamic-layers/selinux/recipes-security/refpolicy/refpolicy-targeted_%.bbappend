FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = "${@bb.utils.contains('DISTRO_FEATURES', 'waydroid', ' file://waydroid.te file://waydroid.fc file://waydroid.if', '', d)}"
EXTRA_OEMAKE:append = "${@bb.utils.contains('DISTRO_FEATURES', 'waydroid', ' APPS_MODS=waydroid', '', d)}"

# refpolicy's `make conf` discovers modules below policy/modules. Install the
# product module before upstream generates modules.conf and compiles policy.
do_compile:prepend() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'waydroid', 'true', 'false', d)}; then
        install -d ${S}/policy/modules/services
        install -m 0644 ${WORKDIR}/waydroid.te ${S}/policy/modules/services/
        install -m 0644 ${WORKDIR}/waydroid.fc ${S}/policy/modules/services/
        install -m 0644 ${WORKDIR}/waydroid.if ${S}/policy/modules/services/
    fi
}
