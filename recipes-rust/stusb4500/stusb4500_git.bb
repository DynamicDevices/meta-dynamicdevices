FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SUMMARY = "STUSB4500 support"
HOMEPAGE = "git://github.com/Atmelfan/stusb4500-rs"

LICENSE = "MIT"

inherit cargo_bin

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

SRC_URI = "git://github.com/DynamicDevices/stusb4500-rs.git;protocol=https;branch=main"

SRCREV="4fa10ee653b120df2e47eed75745ffea5d3a01b6"
S = "${WORKDIR}/git"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3570cec030817fca048fd7f61219a588"

EXTRA_CARGO_FLAGS = "--examples"

RDEPENDS:${PN} += "stusb4500-nvm"
