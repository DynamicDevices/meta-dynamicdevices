# Disable eink-scheduler service by default to prevent board from sleeping too quickly
# This allows easier SSH access for debugging and testing
# Service can be manually enabled with: systemctl enable eink-scheduler
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

# Modify configuration file to add production API configuration section
do_install:append() {
    # Find and modify the configuration example file to add production API settings
    for conf_file in \
        "${D}${datadir}/doc/eink-scheduler/eink-scheduler.conf.example" \
        "${D}${sysconfdir}/eink-scheduler-rust/eink-scheduler.conf.example" \
        "${D}${docdir}/eink-scheduler/eink-scheduler.conf.example"; do
        if [ -f "$conf_file" ]; then
            # Insert production API configuration section after development AUTH_TOKEN line
            awk '/^AUTH_TOKEN=your-bearer-token-here$/ { 
                print; 
                print ""; 
                print "# Production API Configuration (commented out - uncomment for production use)"; 
                print "# API_BASE_URL=https://api.e-tabelone.com"; 
                print "# API_PATH_TEMPLATE=/node/v0/device/{DEVICE_ID}/config"; 
                print "# TELEMETRY_PATH_TEMPLATE=/node/v0/device/{DEVICE_ID}/telemetry"; 
                print "# AUTH_TOKEN=your-bearer-token-here"; 
                next 
            } 
            { print }' "$conf_file" > "$conf_file.tmp" && mv "$conf_file.tmp" "$conf_file"
            break
        fi
    done
}

