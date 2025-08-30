# Example recipe configuration for PROPRIETARY license
# Use this as reference when updating the license

SUMMARY = "EL133UF1 E-Ink Display Driver for Linux"
DESCRIPTION = "Userspace driver for EL133UF1 13.3 inch E-Ink display controller with SPI interface"
HOMEPAGE = "https://github.com/DynamicDevices/eink-spectra6"
SECTION = "graphics"

# PROPRIETARY license configuration
LICENSE = "PROPRIETARY"
LIC_FILES_CHKSUM = "file://LICENSE;md5=<update_with_new_checksum>"

# Mark as commercial license
COMMERCIAL_LICENSE = "1"

# Prevent accidental distribution
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

# Add license warning to package
pkg_postinst:${PN}() {
    echo "WARNING: This software contains proprietary code from E Ink Holdings Inc."
    echo "Distribution is restricted under NDA terms."
}

# Rest of recipe remains the same...
DEPENDS = "libgpiod"
RDEPENDS:${PN} = "libgpiod"

# Source from GitHub (may need to be private repo for proprietary code)
SRC_URI = "git://github.com/DynamicDevices/eink-spectra6.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

inherit cmake pkgconfig

# ... rest of recipe configuration ...
