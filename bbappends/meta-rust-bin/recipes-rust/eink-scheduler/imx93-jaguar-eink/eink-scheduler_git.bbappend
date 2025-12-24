# Machine-specific bbappend for imx93-jaguar-eink only
# This file is in imx93-jaguar-eink/ subdirectory so it's only parsed for that machine
# Disable eink-scheduler service by default to prevent board from sleeping too quickly
# This allows easier SSH access for debugging and testing
# Service can be manually enabled with: systemctl enable eink-scheduler
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

# Replace configuration file with version that includes both dev and production API settings
SRC_URI += "file://eink-scheduler.conf.example"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

do_install:append() {
    # Replace the configuration example file with our version that has both dev and production settings
    if [ -f ${WORKDIR}/eink-scheduler.conf.example ]; then
        # Find where the original config was installed and replace it
        for conf_dir in \
            "${D}${datadir}/doc/eink-scheduler" \
            "${D}${sysconfdir}/eink-scheduler-rust" \
            "${D}${docdir}/eink-scheduler"; do
            if [ -f "$conf_dir/eink-scheduler.conf.example" ]; then
                install -m 0644 ${WORKDIR}/eink-scheduler.conf.example "$conf_dir/eink-scheduler.conf.example"
                break
            fi
        done
    fi
}

