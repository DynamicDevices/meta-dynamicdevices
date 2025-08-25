SUMMARY = "TI TAS256x Driver"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=99021d7f94b3e90e6bb75ba24206af65"

inherit module

SRC_URI = "git://github.com/DynamicDevices/tas2563-android-driver.git;branch=master;protocol=https \
           file://tas2563_uCDSP.bin \
          "
SRCREV = "193335838bd79836f14f82c2b84e1b16817e48b6"

S = "${WORKDIR}/git"

do_configure() {
}

do_install:append() {
  install -d ${D}${nonarch_base_libdir}/firmware
  install -m 755 ${WORKDIR}/tas2563_uCDSP.bin ${D}${nonarch_base_libdir}/firmware
}

FILES:${PN} += "${nonarch_base_libdir}/firmware/tas2563_uCDSP.bin"

KERNEL_MODULE_AUTOLOAD:append = "snd-soc-tas2563"
