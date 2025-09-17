FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SUMMARY = "Spotifyd"
DESCRIPTION = "A spotify daemon"
HOMEPAGE = "https://github.com/Spotifyd/spotifyd"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=84dcc94da3adb52b53ae4fa38fe49e5d"

inherit systemd
inherit cargo_bin

EXTRA_CARGO_FLAGS = "--release"

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

SRC_URI = "git://github.com/Spotifyd/spotifyd.git;protocol=https;branch=master \
          file://spotifyd.service \
"

SRCREV="e342328550779423382f35cd10a18b1c76b81f40"

S = "${WORKDIR}/git"

DEPENDS = "alsa-lib avahi"

do_install:append:imx8mm-jaguar-sentai() {
        install -d ${D}/${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/spotifyd.service ${D}/${systemd_unitdir}/system
}

SYSTEMD_SERVICE:${PN}:imx8mm-jaguar-sentai = "spotifyd.service"
SYSTEMD_AUTO_ENABLE:${PN}:imx8mm-jaguar-sentai = "enable"
