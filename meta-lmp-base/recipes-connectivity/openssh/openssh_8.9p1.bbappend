FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Only apply CVE patch for Dynamic Devices machines
SRC_URI:append:imx8mm-jaguar-sentai = " file://CVE-2024-6387.patch"
SRC_URI:append:imx8mm-jaguar-inst = " file://CVE-2024-6387.patch"
SRC_URI:append:imx8mm-jaguar-handheld = " file://CVE-2024-6387.patch"
SRC_URI:append:imx8mm-jaguar-phasora = " file://CVE-2024-6387.patch"
SRC_URI:append:imx93-jaguar-eink = " file://CVE-2024-6387.patch"
