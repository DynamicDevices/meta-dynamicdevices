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

# Optional MQTT broker for local testing
RDEPENDS:packagegroup-uwb-broker = "\
    ${RDEPENDS:packagegroup-uwb} \
    mosquitto \
    mosquitto-misc \
"

PACKAGES = "\
    packagegroup-uwb \
    packagegroup-uwb-dev \
    packagegroup-uwb-broker \
"

# Allow empty packages (no actual files, just dependencies)
ALLOW_EMPTY:packagegroup-uwb = "1"
ALLOW_EMPTY:packagegroup-uwb-dev = "1"
ALLOW_EMPTY:packagegroup-uwb-broker = "1"