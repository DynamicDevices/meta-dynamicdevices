SUMMARY = "Waydroid uses a container-based approach to boot a full Android system"
DESCRIPTION = "Runtime for Android applications which runs a full Android system \
    in a container using Linux namespaces (user, ipc, net, mount) to \
    separate the Android system fully from the host."
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

SECTION = "webos/support"

SRCREV = "41f309f4c185a2c716723c081274eb56eb9263ff"
SPV = "1.4.2"
PV = "${SPV}+git${SRCPV}"

RDEPENDS:${PN} += "lxc python3-gbinder python3-pygobject libgbinder python3-pyclip python3-dbus python3-compression python3-json gobject-introspection"
RDEPENDS:${PN}:append:imx95-frdm-evk = " ca-certificates curl"

# these modules are directly included in android-flavored kernels
# Note: Waydroid requires kernel >= 3.18 !
RRECOMMENDS:${PN} += "\
    kernel-module-binder-linux \
    kernel-module-ashmem-linux \
"

SRC_URI = "git://github.com/herrie82/waydroid.git;branch=herrie/luneos;protocol=https \
    file://gbinder.conf \
    file://waydroid-net.sh \
    file://waydroid-image-provision \
    file://waydroid-image-release.conf \
    file://waydroid-image-provision.service \
    file://waydroid-jaguar-wait \
    file://waydroid-jaguar-container.service \
    file://waydroid-jaguar-session.service \
    file://waydroid-jaguar-ui.service \
    file://weston-jaguar-waydroid.ini \
    file://90-waydroid-screen.conf \
    file://waydroid-frdm-container.service \
    file://waydroid-frdm-session.service \
    file://waydroid-frdm-ui.service \
    file://waydroid-product-wait \
"
S = "${WORKDIR}/git"

# Needs quite new kernel (probably >= 3.18) and from LuneOS supported machines
# only qemux86, qemux86-64, rpi, Pine64 and other mainline) MACHINEs have it
# Unlink ashmem, binder drop qemux86 here, because waydroid-data is available only
# for following 4 archs (x86-64, armv7a, armv7ve, aarch64)
COMPATIBLE_MACHINE ?= "(^$)"
COMPATIBLE_MACHINE:qemux86-64 = "(.*)"
COMPATIBLE_MACHINE:rpi = "(.*)"
COMPATIBLE_MACHINE:pinephone = "(.*)"
COMPATIBLE_MACHINE:pinephonepro = "(.*)"
COMPATIBLE_MACHINE:pinetab2 = "(.*)"
COMPATIBLE_MACHINE:mido-halium = "(.*)"
COMPATIBLE_MACHINE:tissot = "(.*)"
COMPATIBLE_MACHINE:imx8mm-lpddr4-evk = "(.*)"
COMPATIBLE_MACHINE:imx8mm-jaguar-screen = "(.*)"
COMPATIBLE_MACHINE:imx95-frdm-evk = "(.*)"

inherit pkgconfig
#inherit webos_app
#inherit webos_filesystem_paths
#inherit webos_systemd
inherit features_check systemd

SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-screen = " \
    waydroid-image-provision.service \
    waydroid-jaguar-container.service \
    waydroid-jaguar-session.service \
    waydroid-jaguar-ui.service \
"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-screen = "enable"

SYSTEMD_SERVICE:${PN}:imx95-frdm-evk = " \
    waydroid-image-provision.service \
    waydroid-frdm-container.service \
    waydroid-frdm-session.service \
    waydroid-frdm-ui.service \
"
SYSTEMD_AUTO_ENABLE:${PN}:imx95-frdm-evk = "enable"

# Product configuration selects the provider-neutral `android-container`
# bundle. The distro layer expands that bundle to these implementation
# prerequisites; fail early if Waydroid is pulled into an incomplete image.
REQUIRED_DISTRO_FEATURES = "waydroid wayland opengl vulkan"
REQUIRED_DISTRO_FEATURES:imx8mm-jaguar-screen = "waydroid wayland opengl etnaviv"

WEBOS_SYSTEMD_SERVICE = "waydroid-init.service waydroid-container.service"

CLEANBROKEN = "1"

EXTRA_OEMAKE = "SYSD_DIR=${systemd_system_unitdir} USE_NFTABLES="1" WAYDROID_VERSION=${SPV}"

do_install() {
    make install_luneos DESTDIR=${D}
}

do_install:append() {
    install -Dm0755 ${WORKDIR}/waydroid-image-provision \
        ${D}${libexecdir}/waydroid-image-provision
    install -Dm0644 ${WORKDIR}/waydroid-image-provision.service \
        ${D}${systemd_system_unitdir}/waydroid-image-provision.service
}

# Provided by libgbinder already for Halium devices, but necessary to add for non-Halium devices.

do_install:append:pinephone() {
    install -Dm644 -t "${D}${sysconfdir}" "${WORKDIR}/gbinder.conf"
}

do_install:append:pinephonepro() {
    install -Dm644 -t "${D}${sysconfdir}" "${WORKDIR}/gbinder.conf"
}

do_install:append:pinetab2() {
    install -Dm644 -t "${D}${sysconfdir}" "${WORKDIR}/gbinder.conf"
}

do_install:append:qemux86-64() {
    install -Dm644 -t "${D}${sysconfdir}" "${WORKDIR}/gbinder.conf"
}

do_install:append:imx8mm-lpddr4-evk() {
    install -Dm644 -t "${D}${sysconfdir}" "${WORKDIR}/gbinder.conf"
    install -m 755 ${WORKDIR}/waydroid-net.sh ${D}/usr/lib/waydroid/data/scripts/waydroid-net.sh
}

do_install:append:imx8mm-jaguar-screen() {
    install -Dm644 -t "${D}${sysconfdir}" "${WORKDIR}/gbinder.conf"
    install -m 755 ${WORKDIR}/waydroid-net.sh ${D}/usr/lib/waydroid/data/scripts/waydroid-net.sh

    # LXC executes hook paths.  The inherited LuneOS template uses /dev/null
    # as a no-op post-stop hook, which exits 126 and makes every clean Waydroid
    # shutdown look like a container failure.  Use an executable no-op.
    config_base="${D}${libdir}/waydroid/data/configs/config_base"
    if ! grep -qx 'lxc.hook.post-stop = /dev/null' "${config_base}"; then
        bbfatal "unexpected Waydroid post-stop hook in ${config_base}"
    fi
    sed -i 's|^lxc.hook.post-stop = /dev/null$|lxc.hook.post-stop = /bin/true|' \
        "${config_base}"

    # The display controller is card2 on this board; card0 is the boot
    # framebuffer and card1 is the render-only Etnaviv node.  Pinning card2
    # prevents Weston from selecting the wrong KMS device after boot.
    install -Dm0644 ${WORKDIR}/weston-jaguar-waydroid.ini \
        ${D}${sysconfdir}/xdg/weston/waydroid-screen.ini
    install -Dm0644 ${WORKDIR}/90-waydroid-screen.conf \
        ${D}${systemd_system_unitdir}/weston.service.d/90-waydroid-screen.conf

    install -Dm0755 ${WORKDIR}/waydroid-jaguar-wait \
        ${D}${libexecdir}/waydroid-jaguar-wait
    install -Dm0644 ${WORKDIR}/waydroid-jaguar-container.service \
        ${D}${systemd_system_unitdir}/waydroid-jaguar-container.service
    install -Dm0644 ${WORKDIR}/waydroid-jaguar-session.service \
        ${D}${systemd_system_unitdir}/waydroid-jaguar-session.service
    install -Dm0644 ${WORKDIR}/waydroid-jaguar-ui.service \
        ${D}${systemd_system_unitdir}/waydroid-jaguar-ui.service
}

do_install:append:raspberrypi4-64() {
    install -Dm644 -t "${D}${sysconfdir}" "${WORKDIR}/gbinder.conf"
    install -m 755 ${WORKDIR}/waydroid-net.sh ${D}/usr/lib/waydroid/data/scripts/waydroid-net.sh
}

do_install:append:imx95-frdm-evk() {
    install -Dm644 -t "${D}${sysconfdir}" "${WORKDIR}/gbinder.conf"
    install -m 755 ${WORKDIR}/waydroid-net.sh ${D}/usr/lib/waydroid/data/scripts/waydroid-net.sh

    # Match the Screen product's first-boot provisioning and graphical
    # session flow, while leaving DRM connector/card selection to the FRDM
    # BSP and Weston's normal device discovery.
    config_base="${D}${libdir}/waydroid/data/configs/config_base"
    if ! grep -qx 'lxc.hook.post-stop = /dev/null' "${config_base}"; then
        bbfatal "unexpected Waydroid post-stop hook in ${config_base}"
    fi
    sed -i 's|^lxc.hook.post-stop = /dev/null$|lxc.hook.post-stop = /bin/true|' \
        "${config_base}"

    install -Dm0755 ${WORKDIR}/waydroid-product-wait \
        ${D}${libexecdir}/waydroid-product-wait
    install -Dm0644 ${WORKDIR}/waydroid-image-release.conf \
        ${D}${datadir}/waydroid-extra/waydroid-image-release.conf
    install -Dm0644 ${WORKDIR}/waydroid-frdm-container.service \
        ${D}${systemd_system_unitdir}/waydroid-frdm-container.service
    install -Dm0644 ${WORKDIR}/waydroid-frdm-session.service \
        ${D}${systemd_system_unitdir}/waydroid-frdm-session.service
    install -Dm0644 ${WORKDIR}/waydroid-frdm-ui.service \
        ${D}${systemd_system_unitdir}/waydroid-frdm-ui.service
}

FILES:${PN} += " \
    ${sysconfdir} \
    ${libdir} \
    ${datadir}/dbus-1 \
    ${datadir}/polkit-1 \
    ${datadir}/waydroid-extra \
    ${prefix}/libexec \
    /usr/palm/applications/id.waydro.container \
"
