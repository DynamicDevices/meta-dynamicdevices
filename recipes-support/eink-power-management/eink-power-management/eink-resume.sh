#!/bin/bash
# E-ink Board Resume Script
# Restores the system after waking from low power mode

set -e

LOG_FILE="/var/log/eink-resume.log"

log_message() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

# Restore WiFi after resume
restore_wifi_resume() {
    log_message "Restoring WiFi after resume..."
    
    # Find WiFi interface
    WIFI_INTERFACE=$(ip link show | grep -E "wl[a-z0-9]+" | cut -d: -f2 | tr -d ' ' | head -n1)
    
    if [ -n "$WIFI_INTERFACE" ]; then
        log_message "Found WiFi interface: $WIFI_INTERFACE"
        
        # Restore power management based on load
        if [ "$(cat /proc/loadavg | cut -d' ' -f1 | cut -d'.' -f1)" -gt 1 ]; then
            # High load - disable power save for performance
            iw dev "$WIFI_INTERFACE" set power_save off || log_message "Failed to disable power save"
            log_message "Disabled WiFi power save due to high system load"
        else
            # Low load - keep power save enabled
            iw dev "$WIFI_INTERFACE" set power_save on || log_message "Failed to enable power save"
            log_message "Kept WiFi power save enabled for low system load"
        fi
        
        # Trigger network reconnection if needed
        ip link set "$WIFI_INTERFACE" up || log_message "Failed to bring up WiFi interface"
    else
        log_message "No WiFi interface found"
    fi
}

# Restore Bluetooth after resume
restore_bluetooth_resume() {
    log_message "Restoring Bluetooth after resume..."
    
    # Check if any Bluetooth devices need reconnection
    if command -v bluetoothctl >/dev/null 2>&1; then
        # Scan for known devices
        timeout 10 bluetoothctl scan on || log_message "Bluetooth scan timed out"
        bluetoothctl scan off || log_message "Failed to stop Bluetooth scan"
    fi
}

# Restore LTE modem after resume
restore_lte_resume() {
    log_message "Restoring LTE modem after resume..."
    
    # Check LTE modem connectivity
    if command -v mmcli >/dev/null 2>&1; then
        # List modems and check status
        mmcli -L || log_message "No LTE modems detected"
    fi
}

# Restore system performance after resume
restore_system_resume() {
    log_message "Restoring system performance after resume..."
    
    # Check system load and adjust CPU governor accordingly
    LOAD=$(cat /proc/loadavg | cut -d' ' -f1 | cut -d'.' -f1)
    
    if [ "$LOAD" -gt 2 ]; then
        # High load - use performance governor
        GOVERNOR="performance"
        log_message "High system load detected, setting performance governor"
    elif [ "$LOAD" -gt 1 ]; then
        # Medium load - use ondemand governor
        GOVERNOR="ondemand"
        log_message "Medium system load detected, setting ondemand governor"
    else
        # Low load - use powersave governor for eink use case
        GOVERNOR="powersave"
        log_message "Low system load detected, keeping powersave governor"
    fi
    
    # Set CPU governor
    for governor_file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -f "$governor_file" ]; then
            echo "$GOVERNOR" > "$governor_file"
        fi
    done
    
    log_message "System performance restored with $GOVERNOR governor"
}

# Check wake source
check_wake_source() {
    log_message "Checking wake source..."
    
    if [ -f "/sys/power/pm_wakeup_irq" ]; then
        WAKE_IRQ=$(cat /sys/power/pm_wakeup_irq)
        log_message "System woken by IRQ: $WAKE_IRQ"
    fi
    
    if [ -f "/sys/power/last_wakeup_source" ]; then
        WAKE_SOURCE=$(cat /sys/power/last_wakeup_source)
        log_message "Last wakeup source: $WAKE_SOURCE"
    fi
}

# Main resume restoration
main() {
    log_message "Starting e-ink board resume restoration..."
    
    check_wake_source
    restore_wifi_resume
    restore_bluetooth_resume
    restore_lte_resume
    restore_system_resume
    
    log_message "E-ink board resume restoration completed"
}

main "$@"
