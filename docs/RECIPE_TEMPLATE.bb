# Template for Dynamic Devices recipes
#
# IMPORTANT: The LICENSE field below refers to the license of the SOFTWARE COMPONENT
# being built, NOT the license of this Yocto layer. Common component licenses include:
# - "MIT", "GPL-2.0-only", "GPL-3.0-only", "Apache-2.0", "BSD-3-Clause", etc.
# - For proprietary components: "CLOSED"
# - For multiple licenses: "GPL-2.0-only | MIT"

SUMMARY = "Brief one-line description of the package"
DESCRIPTION = "Detailed description explaining what this package does, \
its purpose, and any important implementation details."
HOMEPAGE = "https://www.dynamicdevices.co.uk"
SECTION = "base"  # or kernel, multimedia, connectivity, etc.

LICENSE = "MIT"  # Use the actual license of the component being built
LIC_FILES_CHKSUM = "file://LICENSE;md5=example-checksum-of-component-license"
# OR if component has no license file:
# LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Version and source information
SRCREV = "git-revision-or-tag"
PV = "1.0+git${SRCPV}"

# Source URI
SRC_URI = "git://github.com/DynamicDevices/example-repo.git;protocol=https;branch=main \
           file://example.patch \
           file://example.service"

# Build dependencies
DEPENDS = "example-lib"
RDEPENDS:${PN} = "example-runtime"

# Machine compatibility (if applicable)
COMPATIBLE_MACHINE = "(imx8mm-jaguar-sentai|imx93-jaguar-eink)"

# Source directory
S = "${WORKDIR}/git"

# Inherit classes
inherit systemd

# Configuration variables
SYSTEMD_SERVICE:${PN} = "example.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Build configuration
EXTRA_OECONF = "--enable-feature"

# Installation
do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${B}/example ${D}${bindir}/
    
    install -d ${D}${systemd_unitdir}/system
    install -m 0644 ${WORKDIR}/example.service ${D}${systemd_unitdir}/system/
}

# Package files
FILES:${PN} += "${bindir}/example \
                ${systemd_unitdir}/system/example.service"

# Package description
PACKAGE_BEFORE_PN = ""
PACKAGES = "${PN} ${PN}-dev ${PN}-dbg"

# Maintainer information
MAINTAINER = "Dynamic Devices <info@dynamicdevices.co.uk>"
