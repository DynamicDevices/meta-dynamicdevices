FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SUMMARY = "STUSB4500 support"
HOMEPAGE = "git://github.com/Atmelfan/stusb4500-rs"

LICENSE = "MIT"

inherit cargo_bin

EXTRA_CARGO_FLAGS = "--workspace --release"

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

SRC_URI = "git://github.com/Atmelfan/stusb4500-rs.git;protocol=https;branch=main"

SRCREV="aa729cd2f4cb3ea06fc8e53f73ed62de4116930d"
S = "${WORKDIR}/git"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3570cec030817fca048fd7f61219a588"

RDEPENDS:${PN} += "stusb4500-nvm"

do_install:append() {
  chmod a+s ${D}${bindir}/stusb4500-utils
}

