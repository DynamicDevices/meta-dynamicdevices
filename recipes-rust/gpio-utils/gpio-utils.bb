SUMMARY = "GPIO Utilities"
HOMEPAGE = "git://github.com/rust-embedded/gpio-utils"
LICENSE = "MIT"

inherit cargo_bin

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

SRC_URI = "git://github.com/rust-embedded/gpio-utils.git;protocol=https;branch=master"
SRCREV="02b0658cd7e13e46f6b1a5de3fd9655711749759"
S = "${WORKDIR}/git"
LIC_FILES_CHKSUM = "file://LICENSE-MIT;md5=935a9b2a57ae70704d8125b9c0e39059"
