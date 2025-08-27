FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Only apply iptables rules for Dynamic Devices machines
SRC_URI:append:imx8mm-jaguar-sentai = " file://iptables.rules"
SRC_URI:append:imx8mm-jaguar-inst = " file://iptables.rules"
SRC_URI:append:imx8mm-jaguar-handheld = " file://iptables.rules"
SRC_URI:append:imx8mm-jaguar-phasora = " file://iptables.rules"
SRC_URI:append:imx93-jaguar-eink = " file://iptables.rules"
