FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Only apply android drivers configuration for Raspberry Pi machines
SRC_URI:append:rpi = " \
    file://android-drivers.cfg \
    "
