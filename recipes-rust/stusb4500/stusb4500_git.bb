FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SUMMARY = "STUSB4500 support"
HOMEPAGE = "git://github.com/Atmelfan/stusb4500-rs"

LICENSE = "MIT"

inherit cargo_bin

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

SRC_URI = "git://github.com/DynamicDevices/stusb4500-rs.git;protocol=https;branch=main"

SRC_URI:append:imx8mm-jaguar-sentai = " file://stusb4500.dat"

SRCREV="4fa10ee653b120df2e47eed75745ffea5d3a01b6"
S = "${WORKDIR}/git"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3570cec030817fca048fd7f61219a588"

EXTRA_CARGO_FLAGS = "--examples"

do_install:append:imx8mm-jaguar-sentai() {
  install -d ${D}/${base_libdir}/firmware
  install -m 0644 ${WORKDIR}/stusb4500.dat ${D}/${base_libdir}/firmware
}

#do_install:append() {
#  rm ${D}/${bindir}/stusb4500-*
#}

#FILES:${PN} += "/usr/bin/stusb4500"
FILES:${PN}:imx8mm-jaguar-sentai += "${base_libdir}/firmware/stusb4500.dat"
