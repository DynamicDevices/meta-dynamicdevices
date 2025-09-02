FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# For mfgtools builds, explicitly disable SE050/ELE to prevent initialization failures
# SE050/ELE secure enclaves are only needed for production runtime, not manufacturing/UUU programming

# Explicitly disable SE050 for all machines in mfgtools builds
# Keep I2C enabled as it may be needed for other components
EXTRA_OEMAKE:append = " \
    CFG_NXP_SE05X=n \
    CFG_CORE_SE05X=n \
    CFG_CORE_SE05X_SCP03_EARLY=n \
    CFG_CORE_SE05X_DISPLAY_INFO=n \
"
