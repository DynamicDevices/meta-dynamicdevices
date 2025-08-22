#!/bin/bash
# E-ink Board Suspend Script
# Prepares the system for low power mode

set -e

LOG_FILE="/var/log/eink-suspend.log"

log_message() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

# Prepare WiFi for suspend
prepare_wifi_suspend() {
    log_message "Preparing WiFi for suspend..."
    
    # Find WiFi interface
    WIFI_INTERFACE=$(ip link show | grep -E "wl[a-z0-9]+" | cut -d: -f2 | tr -d ' ' | head -n1)
    
    if [ -n "$WIFI_INTERFACE" ]; then
        log_message "Found WiFi interface: $WIFI_INTERFACE"
        
        # Enable power save mode before suspend
        iw dev "$WIFI_INTERFACE" set power_save on || log_message "Failed to enable power save"
        
        # Configure wake patterns if supported
        if [ -f "/sys/class/net/$WIFI_INTERFACE/device/power/wakeup" ]; then
            echo enabled > "/sys/class/net/$WIFI_INTERFACE/device/power/wakeup"
            log_message "Enabled WiFi wakeup"
        fi
    else
        log_message "No WiFi interface found"
    fi
}

# Prepare Bluetooth for suspend
prepare_bluetooth_suspend() {
    log_message "Preparing Bluetooth for suspend..."
    
    # Enable Bluetooth wakeup if adapter exists
    if [ -d "/sys/class/bluetooth" ]; then
        for hci in /sys/class/bluetooth/hci*/device/power/wakeup; do
            if [ -f "$hci" ]; then
                echo enabled > "$hci"
                log_message "Enabled Bluetooth wakeup for $(dirname "$hci")"
            fi
        done
    fi
}

# Prepare LTE modem for suspend
prepare_lte_suspend() {
    log_message "Preparing LTE modem for suspend..."
    
    # Enable USB wakeup for LTE modem
    for usb in /sys/bus/usb/devices/*/power/wakeup; do
        if [ -f "$usb" ]; then
            echo enabled > "$usb"
            log_message "Enabled USB wakeup for $(dirname "$usb")"
        fi
    done
}

# Prepare system for suspend
prepare_system_suspend() {
    log_message "Preparing system for suspend..."
    
    # Set all CPUs to powersave governor
    for governor in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -f "$governor" ]; then
            echo powersave > "$governor"
        fi
    done
    
    # Enable runtime PM for all devices
    find /sys/devices -name "power/control" -type f | while read -r control; do
        echo auto > "$control" 2>/dev/null || true
    done
    
    # Sync filesystems
    sync
    
    log_message "System prepared for suspend"
}

# Configure GPIO wakeup sources
configure_gpio_wakeup() {
    log_message "Configuring GPIO wakeup sources..."
    
    # Enable wakeup for WiFi interrupt (GPIO4_25)
    if [ -d "/sys/class/gpio/gpio121" ]; then  # GPIO4_25 = 4*32 + 25 = 121
        echo 1 > /sys/class/gpio/gpio121/edge || log_message "Failed to configure WiFi GPIO wakeup"
    fi
    
    # Enable wakeup for ZigBee interrupt (GPIO4_27)  
    if [ -d "/sys/class/gpio/gpio123" ]; then  # GPIO4_27 = 4*32 + 27 = 123
        echo 1 > /sys/class/gpio/gpio123/edge || log_message "Failed to configure ZigBee GPIO wakeup"
    fi
}

# Main suspend preparation
main() {
    log_message "Starting e-ink board suspend preparation..."
    
    prepare_wifi_suspend
    prepare_bluetooth_suspend
    prepare_lte_suspend
    configure_gpio_wakeup
    prepare_system_suspend
    
    log_message "E-ink board suspend preparation completed"
}

main "$@"
