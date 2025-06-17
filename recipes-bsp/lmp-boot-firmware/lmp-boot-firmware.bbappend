FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

LMP_BOOT_FIRMWARE_FILES:append = " zephyr.bin"

SRC_URI += " \
    file://zephyr.bin \
"
