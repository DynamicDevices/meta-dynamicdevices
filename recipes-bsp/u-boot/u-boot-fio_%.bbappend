FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:imx8mm-jaguar-sentai = " \
    file://custom-dtb.cfg \
    file://01-customise-dtb.patch \
"

