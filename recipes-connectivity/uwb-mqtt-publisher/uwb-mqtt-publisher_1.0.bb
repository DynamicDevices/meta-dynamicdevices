SUMMARY = "UWB MQTT Publisher Service"
DESCRIPTION = "A service that reads UWB positioning data from serial and publishes to MQTT broker"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

SRC_URI = "file://mqtt-live-publisher.py \
           file://uwb-mqtt-publisher.service \
           file://uwb-mqtt-publisher.conf \
           file://uwb-mqtt-publisher.default"

S = "${WORKDIR}"

# Runtime dependencies
RDEPENDS:${PN} = "python3 \
                  python3-pyserial \
                  python3-paho-mqtt \
                  python3-json \
                  python3-threading \
                  python3-ssl \
                  python3-struct \
                  python3-math \
                  python3-time \
                  python3-sys"

# Systemd service
inherit systemd

SYSTEMD_SERVICE:${PN} = "uwb-mqtt-publisher.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Install files
do_install() {
    # Install the Python script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/mqtt-live-publisher.py ${D}${bindir}/uwb-mqtt-publisher

    # Install systemd service file
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/uwb-mqtt-publisher.service ${D}${systemd_system_unitdir}

    # Install configuration files
    install -d ${D}${sysconfdir}/uwb-mqtt-publisher
    install -m 0644 ${WORKDIR}/uwb-mqtt-publisher.conf ${D}${sysconfdir}/uwb-mqtt-publisher/

    # Install default environment file
    install -d ${D}${sysconfdir}/default
    install -m 0644 ${WORKDIR}/uwb-mqtt-publisher.default ${D}${sysconfdir}/default/uwb-mqtt-publisher
}

# Package files
FILES:${PN} += "${bindir}/uwb-mqtt-publisher \
                ${systemd_system_unitdir}/uwb-mqtt-publisher.service \
                ${sysconfdir}/uwb-mqtt-publisher/ \
                ${sysconfdir}/default/uwb-mqtt-publisher"

# Ensure network is available before starting
REQUIRED_DISTRO_FEATURES = "systemd"
