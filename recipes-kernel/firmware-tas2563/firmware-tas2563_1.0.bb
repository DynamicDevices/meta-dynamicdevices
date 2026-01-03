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
    
    # Install TAS2563 regbin firmware with the filename expected by mainline TAS2781 driver
    # tas2563RCA1.bin = Register Configuration Array for TAS2563 (regbin file)
    install -m 644 ${WORKDIR}/tas2563-1amp-reg.bin ${D}${nonarch_base_libdir}/firmware/tas2563RCA1.bin
    
    # Install TAS2563 DSP firmware (CoefBin) for mainline TAS2781 driver  
    # This contains DSP algorithms and acoustic parameters
    install -m 644 ${WORKDIR}/TAS2XXX3870.bin ${D}${nonarch_base_libdir}/firmware/tas2563-coef.bin
}

FILES:${PN} = " \
    ${nonarch_base_libdir}/firmware/tas2563RCA1.bin \
    ${nonarch_base_libdir}/firmware/tas2563-coef.bin \
"

# This firmware is required for TAS2563 codec operation with TAS2781 mainline driver
RDEPENDS:${PN} = ""
RPROVIDES:${PN} = "tas2563-firmware"

# Only install for machines that use TAS2563 with mainline TAS2781 driver
COMPATIBLE_MACHINE = "(imx8mm-jaguar-sentai|imx8mm-jaguar-dt510)"
