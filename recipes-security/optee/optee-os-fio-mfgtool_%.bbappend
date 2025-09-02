FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# For mfgtools builds, completely disable SE050/ELE to prevent initialization failures
# SE050/ELE secure enclaves are only needed for production runtime, not manufacturing/UUU programming

# The key insight: mfgtools use optee-os-fio-mfgtool, not optee-os-fio
# So the conditional logic in optee-os-fio_%.bbappend is never applied to mfgtools builds

# Disable SE050 for imx8mm-jaguar-sentai (external SE050 chip) in mfgtools
# Use conditional logic to only disable when se05x feature is present
EXTRA_OEMAKE:append:imx8mm-jaguar-sentai = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'se05x', \
        'CFG_NXP_SE05X=n CFG_CORE_SE05X=n', \
        '', d)} \
"

# Disable ELE for imx93-jaguar-eink (internal EdgeLock Secure Enclave) in mfgtools  
EXTRA_OEMAKE:append:imx93-jaguar-eink = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'se05x', \
        'CFG_NXP_SE05X=n CFG_CORE_SE05X=n', \
        '', d)} \
"

# Disable SE050 for imx8mm-jaguar-inst (external SE050 chip) in mfgtools
EXTRA_OEMAKE:append:imx8mm-jaguar-inst = " \
    ${@bb.utils.contains('MACHINE_FEATURES', 'se05x', \
        'CFG_NXP_SE05X=n CFG_CORE_SE05X=n', \
        '', d)} \
"
