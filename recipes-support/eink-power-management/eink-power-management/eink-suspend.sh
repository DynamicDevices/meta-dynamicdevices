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
        
        # Configure selective WiFi wake - magic packet only (no broadcast/scan wakeups)
        # This allows intentional remote wake while preventing unwanted network noise
        if command -v iw > /dev/null 2>&1; then
            # Enable WoWLAN with magic packet only - selective wake for eink displays
            iw phy wlan0 wowlan enable magic-packet || log_message "Failed to enable magic packet wake"
            log_message "Enabled selective WiFi wake (magic packet only) - prevents unwanted network wakeups"
        fi
        
        # Enable device-level wakeup for magic packets
        if [ -f "/sys/class/net/$WIFI_INTERFACE/device/power/wakeup" ]; then
            echo enabled > "/sys/class/net/$WIFI_INTERFACE/device/power/wakeup"
            log_message "Enabled WiFi device wakeup for magic packets"
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
    
    # WiFi GPIO wake enabled for magic packets only
    # GPIO4_25 (633) is the WiFi out-of-band wake signal (IRQ 95)
    # WoWLAN filtering ensures only magic packets trigger this GPIO interrupt
    if [ -d "/sys/class/gpio/gpio633" ]; then
        echo rising > /sys/class/gpio/gpio633/edge || log_message "Failed to enable WiFi GPIO wake"
        log_message "WiFi GPIO wake enabled for WoWLAN magic packets (IRQ 95)"
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
