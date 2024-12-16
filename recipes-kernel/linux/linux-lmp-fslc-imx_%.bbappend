FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#KERNEL_REPO = "git://github.com/DynamicDevices/linux-fslc.git"
#KERNEL_BRANCH = "ajl/6.1-2.2.x-imx"
#SRCREV_machine = "b7a6070a84787c49e9891a24bddbc4faaff35a53"

SRC_URI:append:imx8mm-lpddr4-evk = " \
		file://05-prevent-vbus-loss.patch \
"

SRC_URI:append:imx8mm-jaguar-sentai = " \
		file://enable_i2c-dev.cfg \
		file://enable_lp50xx.cfg \
                file://enable_usb_modem.cfg \
		file://enable_gpio_key.cfg \
		file://enable_stts22h.cfg \
		file://enable_lis2dh.cfg \
		file://enable_sht4x.cfg \
		file://imx8mm-jaguar-sentai.dts \
                file://01-fix-enable-lp50xx.patch \
		file://02-disable-wifi-scan-msg.patch \
		file://03-add-st-mems-support.patch \
		file://04-enable-usb-gadgets.cfg \
"

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx8mm-jaguar-sentai(){
 cp ${WORKDIR}/imx8mm-jaguar-sentai.dts ${S}/arch/arm64/boot/dts
 echo "dtb-y += imx8mm-jaguar-sentai.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
}

SRC_URI:append:imx8mm-jaguar-inst = " \
		file://enable_i2c-dev.cfg \
                file://enable_usb_modem.cfg \
		file://enable_gpio_key.cfg \
		file://imx8mm-jaguar-inst.dts \
		file://02-disable-wifi-scan-msg.patch \
		file://04-enable-usb-gadgets.cfg \
"

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx8mm-jaguar-inst(){
 cp ${WORKDIR}/imx8mm-jaguar-inst.dts ${S}/arch/arm64/boot/dts
 echo "dtb-y += imx8mm-jaguar-inst.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
}

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx8mm-jaguar-handheld(){
 cp ${WORKDIR}/imx8mm-jaguar-handheld.dts ${S}/arch/arm64/boot/dts
 echo "dtb-y += imx8mm-jaguar-handheld.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
}

# NOTE: This DTB file is created as a default for use with local development
#       when building lmp-base. It is NOT used by the lmp build or under CI
#       which uses the DTS in lmp-device-tree
do_configure:append:imx8mm-jaguar-phasora(){
 cp ${WORKDIR}/imx8mm-jaguar-phasora.dts ${S}/arch/arm64/boot/dts
 echo "dtb-y += imx8mm-jaguar-phasora.dtb" >> ${S}/arch/arm64/boot/dts/Makefile
}

# TODO: Make binder module based on DISTRO
SRC_URI:append:imx8mm-jaguar-handheld = " \
		file://enable_i2c-dev.cfg \
		file://imx8mm-jaguar-handheld.dts \
                file://enable-binder.cfg \
		file://enable-iptables-ext.cfg \
		file://enable-erofs.cfg \
"

SRC_URI:append:imx8mm-jaguar-phasora = " \
		file://enable_i2c-dev.cfg \
		file://imx8mm-jaguar-phasora.dts \
                file://0003-enable-st7701.cfg \
                file://0006-enable-edt-ft5x06.cfg \
"

#do_configure:append:imx8mm-jaguar-phasora() {
#   for i in ../*.cfg; do
#      [ -f "$i" ] || break
#      bbdebug 2 "applying $i file contents to .config"
#      cat ../*.cfg >> ${B}/.config
#   done
#}
