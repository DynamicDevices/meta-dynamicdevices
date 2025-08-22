#!/bin/bash
# WiFi Power Management Script for E-ink Board
# Optimizes power consumption for the NXP IW612 WiFi module

set -e

# Enable WiFi power saving mode
enable_wifi_power_save() {
    echo "Enabling WiFi power saving mode..."
    
    # Find WiFi interface
    WIFI_INTERFACE=$(ip link show | grep -E "wl[a-z0-9]+" | cut -d: -f2 | tr -d ' ' | head -n1)
    
    if [ -z "$WIFI_INTERFACE" ]; then
        echo "No WiFi interface found, skipping WiFi power management"
        return 0
    fi
    
    echo "Found WiFi interface: $WIFI_INTERFACE"
    
    # Enable power saving mode
    if command -v iw >/dev/null 2>&1; then
        echo "Setting power save mode via iw..."
        iw dev "$WIFI_INTERFACE" set power_save on || echo "Failed to set power save via iw"
    fi
    
    # Enable power management via iwconfig if available
    if command -v iwconfig >/dev/null 2>&1; then
        echo "Setting power management via iwconfig..."
        iwconfig "$WIFI_INTERFACE" power on || echo "Failed to set power management via iwconfig"
    fi
    
    # Configure advanced power management via ethtool if available
    if command -v ethtool >/dev/null 2>&1; then
        echo "Configuring Wake-on-LAN..."
        ethtool -s "$WIFI_INTERFACE" wol g || echo "Failed to configure Wake-on-LAN"
    fi
}

# Configure NXP MOAL driver power settings
configure_moal_power() {
    echo "Configuring NXP MOAL driver power settings..."
    
    # Set low power mode parameters
    if [ -d "/sys/module/moal" ]; then
        echo "MOAL module loaded, configuring power parameters..."
        
        # Enable auto deep sleep
        if [ -f "/sys/module/moal/parameters/auto_ds" ]; then
            echo 1 > /sys/module/moal/parameters/auto_ds || echo "Failed to enable auto deep sleep"
        fi
        
        # Set PS mode to auto
        if [ -f "/sys/module/moal/parameters/ps_mode" ]; then
            echo 1 > /sys/module/moal/parameters/ps_mode || echo "Failed to set PS mode"
        fi
        
        # Enable host sleep
        if [ -f "/sys/module/moal/parameters/hs_wake_interval" ]; then
            echo 400 > /sys/module/moal/parameters/hs_wake_interval || echo "Failed to set host sleep interval"
        fi
    else
        echo "MOAL module not loaded, skipping MOAL configuration"
    fi
}

# Configure system power management
configure_system_power() {
    echo "Configuring system power management..."
    
    # Set CPU governor to powersave for better power efficiency
    if [ -d "/sys/devices/system/cpu/cpufreq" ]; then
        echo "Setting CPU governor to powersave..."
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            if [ -f "$cpu" ]; then
                echo powersave > "$cpu" || echo "Failed to set governor for $cpu"
            fi
        done
    fi
    
    # Enable runtime PM for USB devices (LTE modem)
    echo "Enabling runtime PM for USB devices..."
    for usb_device in /sys/bus/usb/devices/*/power/control; do
        if [ -f "$usb_device" ]; then
            echo auto > "$usb_device" || echo "Failed to enable runtime PM for $usb_device"
        fi
    done
    
    # Configure MMC power management
    echo "Configuring MMC power management..."
    for mmc in /sys/class/mmc_host/mmc*/power/control; do
        if [ -f "$mmc" ]; then
            echo auto > "$mmc" || echo "Failed to configure MMC power management"
        fi
    done
}

# Configure Bluetooth power management
configure_bluetooth_power() {
    echo "Configuring Bluetooth power management..."
    
    # Enable Bluetooth low energy mode if bluetoothctl is available
    if command -v bluetoothctl >/dev/null 2>&1; then
        echo "Configuring Bluetooth power settings..."
        # These commands might fail if no adapter is present, which is OK
        bluetoothctl power off || echo "Bluetooth adapter not available"
        sleep 1
        bluetoothctl power on || echo "Failed to power on Bluetooth"
    fi
}

# Main execution
main() {
    echo "Starting WiFi Power Management configuration for E-ink board..."
    
    # Wait for network to be ready
    sleep 5
    
    enable_wifi_power_save
    configure_moal_power
    configure_system_power
    configure_bluetooth_power
    
    echo "WiFi Power Management configuration completed"
}

main "$@"
