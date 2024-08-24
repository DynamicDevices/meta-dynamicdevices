FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://custom-dtb.cfg \
"

SRC_URI:append:imx8mm-jaguar-sentai = " \
    file://01-customise-dtb.patch \
    file://u-boot-fio-enable-i2c4.patch \
"

