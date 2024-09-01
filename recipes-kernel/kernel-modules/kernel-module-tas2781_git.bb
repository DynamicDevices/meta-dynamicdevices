SUMMARY = "TI TAS2781 Driver"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://tasdevice-codec.c;beginline=1;endline=14;md5=bf3ad78054a3e702be98b345c246c294"

inherit module

SRC_URI = "git://github.com/DynamicDevices/tas2781-linux-driver.git;branch=master;protocol=https"
SRCREV = "2b41f75fe9e5edcd817d3347b3a7b25f5390a06b"

S = "${WORKDIR}/git/src"

do_configure() {
}

#do_install:append() {
#  install -d ${D}${nonarch_base_libdir}/firmware
#  install -m 755 ${WORKDIR}/tas2563_uCDSP.bin ${D}${nonarch_base_libdir}/firmware
#}

#FILES:${PN} += "${nonarch_base_libdir}/firmware/tas2563_uCDSP.bin" 

KERNEL_MODULE_AUTOLOAD:append = "snd-soc-tas2781"
