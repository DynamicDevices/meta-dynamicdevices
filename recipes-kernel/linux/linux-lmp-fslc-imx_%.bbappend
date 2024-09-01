FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#KERNEL_REPO = "git://github.com/DynamicDevices/linux-fslc.git"
#KERNEL_BRANCH = "ajl/6.1-2.2.x-imx"
#SRCREV_machine = "b7a6070a84787c49e9891a24bddbc4faaff35a53"

SRC_URI:append:imx8mm-jaguar-sentai = " \
		file://enable_i2c-dev.cfg \
		file://enable_lp50xx.cfg \
                file://enable_usb_modem.cfg \
		file://enable_gpio_key.cfg \
                file://enable_tas2781.cfg \
		file://imx8mm-jaguar-sentai.dts \
                file://01-fix-enable-lp50xx.patch \
		file://02-disable-wifi-scan-msg.patch \
"

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx8mm-jaguar-sentai(){
 cp ${WORKDIR}/imx8mm-jaguar-sentai.dts ${S}/arch/arm64/boot/dts
 echo "dtb-y += imx8mm-jaguar-sentai.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
}

SRC_URI:append:imx8mm-jaguar-handheld = " \
		file://enable_i2c-dev.cfg \
		file://imx8mm-jaguar-handheld.dts \
"

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx8mm-jaguar-handheld(){
 cp ${WORKDIR}/imx8mm-jaguar-handheld.dts ${S}/arch/arm64/boot/dts
 echo "dtb-y += imx8mm-jaguar-handheld.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
}
