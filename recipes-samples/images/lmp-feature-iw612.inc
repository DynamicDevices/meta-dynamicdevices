# IW612 WiFi 6 Feature - Enhanced WiFi capabilities for NXP IW612 module
# Includes firmware, TWT (Target Wake Time) support for advanced power management
# Specifically designed for ublox MAYA W2 module with IW612 chipset

SUMMARY = "IW612 WiFi 6 enhanced features and TWT support"

# IW612 firmware (original functionality)
CORE_IMAGE_BASE_INSTALL += " \
  linux-firmware-nxpiw612-sdio \
"

# Enhanced iw package with TWT support for IW612 WiFi 6 optimization
IMAGE_INSTALL:append = " \
    iw \
    wpa-supplicant \
"

# Ensure we use the TWT-capable iw version for IW612
PREFERRED_VERSION_iw = "6.9"

# WiFi 6 specific tools and utilities for IW612
IMAGE_INSTALL:append = " \
    wireless-tools \
"

FEATURE_DESCRIPTION = "Enhanced WiFi 6 capabilities and TWT support for NXP IW612 module"