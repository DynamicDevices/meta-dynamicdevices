SUMMARY = "E-ink Display Scheduler"
DESCRIPTION = "Controller-agnostic scheduling service for automated E-ink display content updates. \
Supports multiple display controllers including T2000 USB, Spectra6 SPI, and other compatible devices. \
Provides HTTP API integration, JSON configuration, and systemd service management."
HOMEPAGE = "https://github.com/DynamicDevices/eink-scheduler"
SECTION = "multimedia"
AUTHOR = "Dynamic Devices Ltd"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

SRCBRANCH = "main"
SRC_URI = "git://git@github.com/DynamicDevices/eink-scheduler.git;protocol=ssh;branch=${SRCBRANCH} \
           file://eink-scheduler.service \
           file://eink-scheduler.conf \
"

# Private repository - requires SSH key access in build system
# SSH access should be configured similar to other private repos (eink-spectra6, spi-lib)
BB_GENERATE_MIRROR_TARBALLS = "0"

# Version from repository
PV = "1.0.0+git${SRCPV}"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

# Dependencies for eink-scheduler
DEPENDS = "curl json-c cmake-native pkgconfig-native"
RDEPENDS:${PN} = "curl json-c bash"

# Use CMake build system with systemd support
inherit cmake systemd

# Cross-compilation configuration
EXTRA_OECMAKE = " \
    -DCMAKE_BUILD_TYPE=Release \
    -DTARGET_ARCH=${TARGET_ARCH} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_INSTALL_BINDIR=${bindir} \
    -DCMAKE_INSTALL_LIBDIR=${libdir} \
    -DCMAKE_INSTALL_INCLUDEDIR=${includedir} \
    -DCMAKE_PREFIX_PATH=${STAGING_DIR_HOST}${prefix} \
    -DCMAKE_FIND_ROOT_PATH=${STAGING_DIR_HOST} \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    -DPKG_CONFIG_USE_CMAKE_PREFIX_PATH=ON \
"

do_install:append() {
    # Install systemd service file
    install -d ${D}${systemd_system_unitdir}
    if [ -f "${S}/systemd/eink-scheduler.service" ]; then
        install -m 0644 ${S}/systemd/eink-scheduler.service ${D}${systemd_system_unitdir}/
    else
        # Use fallback from WORKDIR if source doesn't have it
        install -m 0644 ${WORKDIR}/eink-scheduler.service ${D}${systemd_system_unitdir}/
    fi
    
    # Install configuration directory and default config
    install -d ${D}${sysconfdir}/eink-scheduler
    if [ -f "${S}/systemd/eink-scheduler.conf" ]; then
        install -m 0644 ${S}/systemd/eink-scheduler.conf ${D}${sysconfdir}/eink-scheduler/
    else
        # Use fallback from WORKDIR if source doesn't have it
        install -m 0644 ${WORKDIR}/eink-scheduler.conf ${D}${sysconfdir}/eink-scheduler/
    fi
    
    # Create log directory
    install -d ${D}${localstatedir}/log/eink-scheduler
}

# Package configuration
PACKAGES = "${PN} ${PN}-dev ${PN}-dbg"

FILES:${PN} = " \
    ${bindir}/eink-scheduler \
    ${sysconfdir}/eink-scheduler/* \
    ${systemd_system_unitdir}/eink-scheduler.service \
    ${localstatedir}/log/eink-scheduler \
"

FILES:${PN}-dev = " \
    ${includedir}/* \
    ${libdir}/lib*.so \
    ${libdir}/pkgconfig/* \
"

# Systemd service configuration
SYSTEMD_SERVICE:${PN} = "eink-scheduler.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Security and permissions
INSANE_SKIP:${PN} = "already-stripped"
