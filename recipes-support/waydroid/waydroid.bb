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

# these modules are directly included in android-flavored kernels
# Note: Waydroid requires kernel >= 3.18 !
RRECOMMENDS:${PN} += "\
    kernel-module-binder-linux \
    kernel-module-ashmem-linux \
"

SRC_URI = "git://github.com/herrie82/waydroid.git;branch=herrie/luneos;protocol=https \
    file://gbinder.conf \
    file://waydroid-net.sh \
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

inherit pkgconfig
#inherit webos_app
#inherit webos_filesystem_paths
#inherit webos_systemd
inherit systemd

WEBOS_SYSTEMD_SERVICE = "waydroid-init.service waydroid-container.service"

CLEANBROKEN = "1"

EXTRA_OEMAKE = "SYSD_DIR=${systemd_system_unitdir} USE_NFTABLES="1" WAYDROID_VERSION=${SPV}"

do_install() {
    make install_luneos DESTDIR=${D}
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

do_install:append:raspberrypi4-64() {
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
