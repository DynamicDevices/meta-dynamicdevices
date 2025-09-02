FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# For mfgtools builds, explicitly disable SE050/ELE to prevent initialization failures
# SE050/ELE secure enclaves are only needed for production runtime, not manufacturing/UUU programming

# For mfgtools builds, disable SE050 initialization but keep crypto drivers
# This prevents SE050 hardware initialization while preserving crypto functionality
EXTRA_OEMAKE:append = " \
    CFG_CORE_SE05X_SCP03_EARLY=n \
    CFG_CORE_SE05X_DISPLAY_INFO=n \
    CFG_CORE_SE05X_INIT_NVM=n \
    CFG_CORE_SE05X_SCP03_PROVISION_ON_INIT=n \
"
