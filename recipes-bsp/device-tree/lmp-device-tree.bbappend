FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:imx8ulp-lpddr4-evk = " \
        file://imx8ulp-evk.dts \
"

COMPATIBLE_MACHINE:imx8ulp-lpddr4-evk = ".*"
