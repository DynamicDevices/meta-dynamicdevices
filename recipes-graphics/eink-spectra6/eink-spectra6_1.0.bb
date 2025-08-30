SUMMARY = "EL133UF1 E-Ink Display Driver for Linux"
DESCRIPTION = "Userspace driver for EL133UF1 13.3 inch E-Ink display controller with SPI interface"
HOMEPAGE = "https://github.com/DynamicDevices/eink-spectra6"
SECTION = "graphics"

# WARNING: This software is received under NDA from E Ink Holdings Inc.
# The license may need to be changed to COMMERCIAL or PROPRIETARY
# Review LICENSE_NOTES.md for details
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=cb0cf33e845d3825f950a15416b1b7d6"

DEPENDS = "libgpiod"
RDEPENDS:${PN} = "libgpiod"

# Source files (local development version)
# For production, replace with actual source repository or tarball
SRC_URI = "file://eink-driver-stub.c \
           file://eink-driver-stub.h \
           file://CMakeLists.txt \
           file://LICENSE \
          "

S = "${WORKDIR}"

inherit cmake pkgconfig

# CMake configuration
EXTRA_OECMAKE = "-DCMAKE_BUILD_TYPE=Release"

# Enable libgpiod support if available
PACKAGECONFIG ??= "libgpiod"
PACKAGECONFIG[libgpiod] = "-DHAVE_LIBGPIOD=ON,,libgpiod,libgpiod"

# Kernel modules required for SPI and GPIO
RRECOMMENDS:${PN} += "kernel-module-spi-dev kernel-module-gpio-sysfs"

# Package files
FILES:${PN} = "${bindir}/el133uf1_test \
               ${bindir}/el133uf1_demo \
               ${libdir}/libel133uf1.so.* \
               ${sysconfdir}/udev/rules.d/99-el133uf1.rules \
              "

FILES:${PN}-dev = "${includedir}/el133uf1/*.h \
                   ${libdir}/libel133uf1.so \
                   ${libdir}/libel133uf1.a \
                  "

FILES:${PN}-doc = "${datadir}/doc/el133uf1/*.md"

# Create separate packages
PACKAGES = "${PN}-dbg ${PN}-staticdev ${PN}-dev ${PN}-doc ${PN}"

# Installation
do_install:append() {
    # Create udev rules for SPI device permissions
    install -d ${D}${sysconfdir}/udev/rules.d
    cat > ${D}${sysconfdir}/udev/rules.d/99-el133uf1.rules << EOF
# EL133UF1 E-Ink Display SPI device permissions
SUBSYSTEM=="spidev", ATTRS{modalias}=="spi:el133uf1", MODE="0666", GROUP="spi"
SUBSYSTEM=="gpio", ACTION=="add", PROGRAM="/bin/sh -c 'chown root:gpio /sys/class/gpio/export /sys/class/gpio/unexport; chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport'"
EOF

    # Create systemd service file for demo (optional)
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${systemd_system_unitdir}
        cat > ${D}${systemd_system_unitdir}/el133uf1-demo.service << EOF
[Unit]
Description=EL133UF1 E-Ink Display Demo
After=multi-user.target

[Service]
Type=oneshot
ExecStart=${bindir}/el133uf1_demo white
RemainAfterExit=no
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF
    fi
}

# Add systemd service to package if enabled
FILES:${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', '${systemd_system_unitdir}/el133uf1-demo.service', '', d)}"

inherit ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd', '', d)}

SYSTEMD_SERVICE:${PN} = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'el133uf1-demo.service', '', d)}"
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

# Runtime dependencies for GPIO and SPI access
RDEPENDS:${PN} += "bash"

# Add gpio group for GPIO access
USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM:${PN} = "gpio"
inherit useradd

# Post-install script to set up GPIO permissions
pkg_postinst:${PN}() {
    if [ -n "$D" ]; then
        exit 1
    fi
    
    # Create gpio group if it doesn't exist
    if ! getent group gpio > /dev/null; then
        groupadd gpio
    fi
    
    # Set up GPIO sysfs permissions
    if [ -d /sys/class/gpio ]; then
        chown root:gpio /sys/class/gpio/export /sys/class/gpio/unexport 2>/dev/null || true
        chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport 2>/dev/null || true
    fi
    
    # Reload udev rules
    if command -v udevadm >/dev/null 2>&1; then
        udevadm control --reload-rules
        udevadm trigger
    fi
}

# Build-time tests
do_compile:append() {
    # Run basic compilation tests
    if [ -f "${B}/el133uf1_test" ]; then
        echo "Test binary compiled successfully"
    else
        bbfatal "Test binary compilation failed"
    fi
}

# QA checks
INSANE_SKIP:${PN} = "dev-so"

# Provides
PROVIDES = "eink-spectra6"

# Compatible machines - adjust as needed for your hardware
COMPATIBLE_MACHINE = "(imx93-jaguar-eink|.*)"

# Architecture specific
PACKAGE_ARCH = "${MACHINE_ARCH}"
