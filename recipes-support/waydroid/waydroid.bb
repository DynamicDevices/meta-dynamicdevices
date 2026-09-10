SUMMARY = "Waydroid uses a container-based approach to boot a full Android system"
DESCRIPTION = "Runtime for Android applications which runs a full Android system \
    in a container using Linux namespaces (user, ipc, net, mount) to \
    separate the Android system fully from the host."
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

SECTION = "webos/support"

SRCREV = "5b7e2e71be3f6bfaaaab3b461251dacaf1ce4991"
SPV = "1.6.3"
PV = "${SPV}+git${SRCPV}"


RDEPENDS:${PN} += "lxc python3-gbinder python3-pygobject libgbinder python3-pyclip python3-dbus python3-compression python3-json gobject-introspection"

# these modules are directly included in android-flavored kernels
# Note: Waydroid requires kernel >= 3.18 !
RRECOMMENDS:${PN} += "\
    kernel-module-binder-linux \
    kernel-module-ashmem-linux \
"

SRC_URI = "git://github.com/waydroid/waydroid.git;branch=main;protocol=https \
    file://0001-lxc-limit-graphics-device-permissions.patch \
    file://0002-lxc-provide-writable-android-metadata.patch \
    file://gbinder.conf \
    file://waydroid-luneos.env \
    file://waydroid-luneos-appinfo.json \
    file://waydroid-luneos.sh \
    file://waydroid-net.sh \
    file://waydroid-image-provision \
    file://waydroid-image-provision.service \
"
SRC_URI:append:imx8mm-jaguar-screen = " \
    file://waydroid-zram \
    file://waydroid-zram.service \
    file://waydroid-container-2gb.conf \
    file://waydroid-memory-headroom \
    file://waydroid-frame-headroom \
    file://waydroid-board-evidence \
    file://waydroid-acceleration-check \
    file://waydroid-v4l2-probe \
    file://waydroid-vsidaemon.service \
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

SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-screen = "waydroid-image-provision.service"
SYSTEMD_SERVICE:${PN}:append:imx8mm-jaguar-screen = " waydroid-zram.service waydroid-vsidaemon.service"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-screen = "enable"

RDEPENDS:${PN}:append:imx8mm-jaguar-screen = " apparmor kmod util-linux-mkswap util-linux-swaponoff imx-vpu-hantro"

# Product configuration selects the provider-neutral `android-container`
# bundle. The distro layer expands that bundle to these implementation
# prerequisites; fail early if Waydroid is pulled into an incomplete image.
REQUIRED_DISTRO_FEATURES = "waydroid wayland opengl"
REQUIRED_DISTRO_FEATURES:append:imx8mm-jaguar-screen = " apparmor etnaviv"

WEBOS_SYSTEMD_SERVICE = "waydroid-init.service waydroid-container.service"

CLEANBROKEN = "1"

EXTRA_OEMAKE = "PREFIX=${prefix} SYSCONFDIR=${sysconfdir} SYSD_DIR=${systemd_system_unitdir} USE_NFTABLES=1"

do_install() {
    oe_runmake install install_apparmor DESTDIR=${D}

    # Keep the small webOS/LuneOS launcher integration out of the upstream
    # source tree so that the maintained Waydroid release can remain pinned.
    install -d ${D}${prefix}/palm/applications/id.waydro.container
    install -d ${D}${sysconfdir}/id.waydro.Container
    install -m 0644 ${S}/data/AppIcon.png \
        ${D}${prefix}/palm/applications/id.waydro.container/icon.png
    install -m 0644 ${WORKDIR}/waydroid-luneos-appinfo.json \
        ${D}${prefix}/palm/applications/id.waydro.container/appinfo.json
    sed -i -e 's:__VERSION__:${SPV}:g' \
        ${D}${prefix}/palm/applications/id.waydro.container/appinfo.json
    install -m 0755 ${WORKDIR}/waydroid-luneos.sh \
        ${D}${prefix}/palm/applications/id.waydro.container/waydroid.sh
    install -m 0644 ${WORKDIR}/waydroid-luneos.env \
        ${D}${sysconfdir}/id.waydro.Container/waydroid.env
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
    install -Dm0755 ${WORKDIR}/waydroid-zram ${D}${libexecdir}/waydroid-zram
    install -Dm0755 ${WORKDIR}/waydroid-memory-headroom ${D}${libexecdir}/waydroid-memory-headroom
    install -Dm0755 ${WORKDIR}/waydroid-frame-headroom ${D}${libexecdir}/waydroid-frame-headroom
    install -Dm0755 ${WORKDIR}/waydroid-board-evidence ${D}${libexecdir}/waydroid-board-evidence
    install -Dm0755 ${WORKDIR}/waydroid-acceleration-check ${D}${libexecdir}/waydroid-acceleration-check
    install -Dm0755 ${WORKDIR}/waydroid-v4l2-probe ${D}${libexecdir}/waydroid-v4l2-probe
    install -Dm0644 ${WORKDIR}/waydroid-zram.service \
        ${D}${systemd_system_unitdir}/waydroid-zram.service
    install -Dm0644 ${WORKDIR}/waydroid-vsidaemon.service \
        ${D}${systemd_system_unitdir}/waydroid-vsidaemon.service
    install -d ${D}${systemd_system_unitdir}/waydroid-container.service.d
    install -m 0644 ${WORKDIR}/waydroid-container-2gb.conf \
        ${D}${systemd_system_unitdir}/waydroid-container.service.d/20-memory-2gb.conf
}

do_install:append:raspberrypi4-64() {
    install -Dm644 -t "${D}${sysconfdir}" "${WORKDIR}/gbinder.conf"
    install -m 755 ${WORKDIR}/waydroid-net.sh ${D}/usr/lib/waydroid/data/scripts/waydroid-net.sh
}

do_install:append:imx95-frdm-evk() {
    install -Dm644 -t "${D}${sysconfdir}" "${WORKDIR}/gbinder.conf"
    install -m 755 ${WORKDIR}/waydroid-net.sh ${D}/usr/lib/waydroid/data/scripts/waydroid-net.sh
}

FILES:${PN} += " \
    ${sysconfdir} \
    ${libdir} \
    ${datadir}/dbus-1 \
    ${datadir}/polkit-1 \
    ${prefix}/libexec \
    /usr/palm/applications/id.waydro.container \
"


# Usage
# =====
# Below is obsolete since Waydroid can now just be started from Launcher, however it's good to keep for reference
#
# mkdir -p /run/luna-session/
# mount --bind /tmp/luna-session /run/luna-session/
# export XDG_RUNTIME_DIR=/run/luna-session
# export XDG_SESSION_TYPE=wayland
# -- also, make sure /etc/gbinder.conf has "ApiLevel = 30" (Halium 9 needs API 28)
#
# Then:
# 0. waydroid init (just once, but needs network !)
# 1. either
#      waydroid show-full-ui
#    or
#      waydroid session start
#      waydroid app launch com.android.settings
