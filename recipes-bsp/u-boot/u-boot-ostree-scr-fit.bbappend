FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit lmp-signing-override

#SRC_URI:append:imx8mm-jaguar-sentai = " \
#    file://boot.cmd \
#"

SRC_URI:append:imx8mm-jaguar-inst = " \
    file://boot.cmd \
"

SRC_URI:append:imx8mm-jaguar-handheld = " \
    file://boot.cmd \
"

SRC_URI:append:imx8mm-jaguar-phasora = " \
    file://boot.cmd \
"

#SRC_URI:append:imx8ulp-lpddr4-evk = " \
#    file://boot.cmd \
#"
