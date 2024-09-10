SUMMARY = "ST USB 4500 support"
HOMEPAGE = "git://github.com/Atmelfan/stusb4500-rs"

LICENSE = "MIT"

inherit cargo_bin

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

SRC_URI = "git://github.com/DynamicDevices/stusb4500-rs.git;protocol=https;branch=main"
SRCREV="890be07bafa4e0f24c5fc8fdbddcb5f169e790fd"
S = "${WORKDIR}/git"
LIC_FILES_CHKSUM = "file://LICENSE;md5=3570cec030817fca048fd7f61219a588"

EXTRA_CARGO_FLAGS = "--examples"
