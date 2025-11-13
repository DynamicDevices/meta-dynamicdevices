SUMMARY = "UWB MQTT Publisher Service"
DESCRIPTION = "A service that reads UWB positioning data from serial and publishes to MQTT broker"
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

SRC_URI = "git://github.com/DynamicDevices/uwb-mqtt-publisher.git;protocol=https;branch=main \
           file://uwb-mqtt-publisher.service \
           file://uwb-mqtt-publisher.conf \
           file://uwb-mqtt-publisher.default"

SRCREV = "${AUTOREV}"
PV = "1.0+git${SRCPV}"

S = "${WORKDIR}/git"

# Runtime dependencies
RDEPENDS:${PN} = "python3 \
                  python3-pyserial \
                  python3-paho-mqtt \
"

# Systemd service
inherit systemd

SYSTEMD_SERVICE:${PN} = "uwb-mqtt-publisher.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

# Install files
do_install() {
    # Install the Python scripts from git repository (now in src/ directory)
    install -d ${D}${bindir}
    install -m 0755 ${S}/src/mqtt-live-publisher.py ${D}${bindir}/uwb-mqtt-publisher
    install -m 0644 ${S}/src/uwb_network_converter.py ${D}${bindir}/uwb_network_converter.py
    install -m 0644 ${S}/src/lora_tag_cache.py ${D}${bindir}/lora_tag_cache.py

    # Install anchor configuration from git repository (now in config/ directory)
    install -d ${D}${sysconfdir}
    install -m 0644 ${S}/config/uwb_anchors.json ${D}${sysconfdir}/uwb_anchors.json
    install -m 0644 ${S}/config/uwb_anchors_hw_lab.json ${D}${sysconfdir}/uwb_anchors_hw_lab.json

    # Install systemd service file (from local files directory or git repository)
    install -d ${D}${systemd_system_unitdir}
    # Try local file first, fall back to git repository
    if [ -f ${WORKDIR}/uwb-mqtt-publisher.service ]; then
        install -m 0644 ${WORKDIR}/uwb-mqtt-publisher.service ${D}${systemd_system_unitdir}
    else
        install -m 0644 ${S}/systemd/uwb-mqtt-publisher.service ${D}${systemd_system_unitdir}
    fi

    # Install configuration files (from local files directory or git repository)
    install -d ${D}${sysconfdir}/uwb-mqtt-publisher
    if [ -f ${WORKDIR}/uwb-mqtt-publisher.conf ]; then
        install -m 0644 ${WORKDIR}/uwb-mqtt-publisher.conf ${D}${sysconfdir}/uwb-mqtt-publisher/
    else
        install -m 0644 ${S}/config/uwb-mqtt-publisher.conf ${D}${sysconfdir}/uwb-mqtt-publisher/
    fi

    # Install default environment file (from local files directory or git repository)
    install -d ${D}${sysconfdir}/default
    if [ -f ${WORKDIR}/uwb-mqtt-publisher.default ]; then
        install -m 0644 ${WORKDIR}/uwb-mqtt-publisher.default ${D}${sysconfdir}/default/uwb-mqtt-publisher
    else
        install -m 0644 ${S}/config/uwb-mqtt-publisher.default ${D}${sysconfdir}/default/uwb-mqtt-publisher
    fi
}

# Package files
FILES:${PN} += "${bindir}/uwb-mqtt-publisher \
                ${bindir}/uwb_network_converter.py \
                ${bindir}/lora_tag_cache.py \
                ${sysconfdir}/uwb_anchors.json \
                ${sysconfdir}/uwb_anchors_hw_lab.json \
                ${systemd_system_unitdir}/uwb-mqtt-publisher.service \
                ${sysconfdir}/uwb-mqtt-publisher/ \
                ${sysconfdir}/default/uwb-mqtt-publisher"

# Ensure network is available before starting
REQUIRED_DISTRO_FEATURES = "systemd"
