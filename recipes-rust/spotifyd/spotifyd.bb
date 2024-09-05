SUMMARY = "SpotifyD"
DESCRIPTION = "A spotify daemon"
HOMEPAGE = "https://github.com/Spotifyd/spotifyd"
LICENSE = "GPLv3-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=935a9b2a57ae70704d8125b9c0e39059"

inherit cargo_bin

# Enable network for the compile task allowing cargo to download dependencies
do_compile[network] = "1"

SRC_URI = "git://github.com/Spotifyd/spotifyd.git;protocol=https;branch=master"
SRCREV="e342328550779423382f35cd10a18b1c76b81f40"
S = "${WORKDIR}/git"
