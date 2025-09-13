SUMMARY = "TAS2563 Firmware Files for TAS2781 Mainline Driver"
DESCRIPTION = "Provides regbin and DSP firmware files required by the mainline TAS2781 driver \
for TAS2563 codec operation. Includes speaker protection algorithms and audio processing firmware."

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Proprietary;md5=0557f9d92cf58f2ccdd50f62f8ac0b28"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI = " \
    file://tas2563-1amp-reg.bin \
    file://TAS2XXX3870.bin \
"

S = "${WORKDIR}"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${nonarch_base_libdir}/firmware
    
    # Install TAS2563 regbin firmware for mainline TAS2781 driver
    install -m 644 ${WORKDIR}/tas2563-1amp-reg.bin ${D}${nonarch_base_libdir}/firmware/tas2563-1amp-reg.bin
    
    # Install TAS2563 DSP firmware for mainline TAS2781 driver
    install -m 644 ${WORKDIR}/TAS2XXX3870.bin ${D}${nonarch_base_libdir}/firmware/tas2563-1amp-dsp.bin
}

FILES:${PN} = " \
    ${nonarch_base_libdir}/firmware/tas2563-1amp-reg.bin \
    ${nonarch_base_libdir}/firmware/tas2563-1amp-dsp.bin \
"

# This firmware is required for TAS2563 codec operation with TAS2781 mainline driver
RDEPENDS:${PN} = ""
RPROVIDES:${PN} = "tas2563-firmware"

# Only install for machines that use TAS2563 with mainline TAS2781 driver
COMPATIBLE_MACHINE = "(imx8mm-jaguar-sentai)"
