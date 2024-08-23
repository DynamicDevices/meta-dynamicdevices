FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:imx8mm-jaguar-sentai = " \
    file://boot.cmd \
"

SRC_URI:append:imx8mm-jaguar-handheld = " \
    file://boot.cmd \
"
