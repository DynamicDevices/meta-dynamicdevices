FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Refpolicy builds policy text with explicitly declared host-native SELinux
# tools and passes BUILD_CC to its makefiles. It has no target-compiled code,
# so the default target compiler/libc dependency is both unused and especially
# expensive in LmP's global Clang configuration.
INHIBIT_DEFAULT_DEPS = "1"

WAYDROID_SELINUX_DEVELOPMENT_PERMISSIVE ?= "0"

python __anonymous() {
    if (bb.utils.contains('DISTRO_FEATURES', 'waydroid', True, False, d)
            and d.getVar('WAYDROID_SELINUX_DEVELOPMENT_PERMISSIVE') == '1'
            and d.getVar('LOCAL_DEVELOPMENT_BUILD') != '1'):
        bb.fatal('A permissive Waydroid SELinux domain is restricted to LOCAL_DEVELOPMENT_BUILD=1')
}

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
        if [ "${WAYDROID_SELINUX_DEVELOPMENT_PERMISSIVE}" = "1" ]; then
            sed -i 's/^# WAYDROID_DEVELOPMENT_PERMISSIVE$/permissive waydroid_t;/' \
                ${S}/policy/modules/services/waydroid.te
        fi
    fi
}
