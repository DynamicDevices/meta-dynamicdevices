FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:imx8mm-jaguar-sentai = " \
	file://u-boot-fio-enable-i2c4.patch \
"
