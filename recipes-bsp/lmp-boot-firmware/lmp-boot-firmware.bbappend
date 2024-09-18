FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

PV = "1"

LMP_BOOT_FIRMWARE_FILES:append = " zephyr.bin"

SRC_URI += " \
    file://zephyr.bin \
"
