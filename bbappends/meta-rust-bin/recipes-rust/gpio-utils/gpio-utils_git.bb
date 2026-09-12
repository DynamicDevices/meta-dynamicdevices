SUMMARY = "GPIO Utilities"
HOMEPAGE = "git://github.com/rust-embedded/gpio-utils"
LICENSE = "MIT"

inherit cargo_bin

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

# Fix buildpaths QA warnings by ensuring debug prefix mapping is applied to Rust builds
RUSTFLAGS:append = " --remap-path-prefix=${WORKDIR}=/usr/src/debug/${PN}/${PV}"
RUSTFLAGS:append = " --remap-path-prefix=${TMPDIR}=/usr/src/debug/tmpdir"

# gpio-utils' old backtrace-sys dependency builds bundled C sources from
# Cargo's registry.  Rust's remap flags do not reach that C compiler, and the
# standard Yocto CFLAGS only cover ${S} and ${B}, leaving cargo_home embedded
# in the split debug binary.  Remap the whole recipe work directory for C too.
CFLAGS:append = " -ffile-prefix-map=${WORKDIR}=/usr/src/debug/${PN}/${PV}"

SRC_URI = "git://github.com/rust-embedded/gpio-utils.git;protocol=https;branch=master"
SRCREV="02b0658cd7e13e46f6b1a5de3fd9655711749759"
S = "${WORKDIR}/git"
LIC_FILES_CHKSUM = "file://LICENSE-MIT;md5=935a9b2a57ae70704d8125b9c0e39059"
