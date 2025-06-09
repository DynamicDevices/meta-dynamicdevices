SUMMARY = "UWB positioning system packages"
DESCRIPTION = "Package group for UWB (Ultra-Wideband) positioning system components"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit packagegroup

# Main UWB packages
RDEPENDS:packagegroup-uwb = "\
    uwb-mqtt-publisher \
    python3-paho-mqtt \
    python3-pyserial \
    mosquitto-clients \
"

# Optional debugging and development tools
RDEPENDS:packagegroup-uwb-dev = "\
    ${RDEPENDS:packagegroup-uwb} \
    minicom \
    screen \
    socat \
    tcpdump \
    wireshark-cli \
    python3-dev \
    python3-pip \
"

PACKAGES = "\
    packagegroup-uwb \
    packagegroup-uwb-dev \
"

# Allow empty packages (no actual files, just dependencies)
ALLOW_EMPTY:packagegroup-uwb = "1"
ALLOW_EMPTY:packagegroup-uwb-dev = "1"
