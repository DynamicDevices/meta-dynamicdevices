FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# For mfgtools builds, completely disable SE050/ELE to prevent initialization failures
# SE050/ELE secure enclaves are only needed for production runtime, not manufacturing/UUU programming

# Disable SE050 for imx8mm-jaguar-sentai (external SE050 chip)
EXTRA_OEMAKE:append:imx8mm-jaguar-sentai = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'se05x', '', '', d)} \
"

# Disable ELE for imx93-jaguar-eink (internal EdgeLock Secure Enclave)  
EXTRA_OEMAKE:append:imx93-jaguar-eink = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'se05x', '', '', d)} \
"

# Disable SE050 for imx8mm-jaguar-inst (external SE050 chip)
EXTRA_OEMAKE:append:imx8mm-jaguar-inst = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'se05x', '', '', d)} \
"
