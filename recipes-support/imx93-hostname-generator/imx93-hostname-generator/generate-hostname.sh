#!/bin/bash
# Custom hostname generator for i.MX93 Jaguar E-Ink board
# Since OCOTP driver doesn't support i.MX93, use alternative methods

set -e

HOSTNAME_FILE="/etc/hostname"
MACHINE_PREFIX="imx93-jaguar-eink"
LOG_FILE="/var/log/hostname-generator.log"

log_message() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

# Function to generate unique ID from available hardware sources
generate_unique_id() {
    local unique_id=""
    
    # Method 1: Try to read MAC address from WiFi interface
    if [ -d "/sys/class/net/wlan0" ]; then
        local mac_addr=$(cat /sys/class/net/wlan0/address 2>/dev/null | tr -d ':' | tail -c 9)
        if [ -n "$mac_addr" ] && [ "$mac_addr" != "00000000" ]; then
            unique_id="$mac_addr"
            log_message "Using WiFi MAC address for unique ID: $unique_id"
            echo "$unique_id"
            return 0
        fi
    fi
    
    # Method 2: Try to read from device tree serial number
    local dt_serial=$(cat /proc/device-tree/serial-number 2>/dev/null | tr -d '\0' | tail -c 8)
    if [ -n "$dt_serial" ] && [ "$dt_serial" != "00000000" ]; then
        unique_id="$dt_serial"
        log_message "Using device tree serial number for unique ID: $unique_id"
        echo "$unique_id"
        return 0
    fi
    
    # Method 3: Try to read from DMI product serial
    local dmi_serial=$(cat /sys/class/dmi/id/product_serial 2>/dev/null | tail -c 8)
    if [ -n "$dmi_serial" ] && [ "$dmi_serial" != "Not Specified" ]; then
        unique_id="$dmi_serial"
        log_message "Using DMI product serial for unique ID: $unique_id"
        echo "$unique_id"
        return 0
    fi
    
    # Method 4: Try to read from machine ID
    if [ -f "/etc/machine-id" ]; then
        local machine_id=$(cat /etc/machine-id | tail -c 9)
        if [ -n "$machine_id" ]; then
            unique_id="$machine_id"
            log_message "Using machine ID for unique ID: $unique_id"
            echo "$unique_id"
            return 0
        fi
    fi
    
    # Method 5: Generate from CPU info and boot time
    local cpu_info=$(cat /proc/cpuinfo | grep -E "(processor|Hardware|Revision)" | md5sum | cut -c1-8)
    local boot_time=$(stat -c %Y /proc/1 | tail -c 5)
    unique_id="${cpu_info}${boot_time}"
    log_message "Generated unique ID from CPU info and boot time: $unique_id"
    echo "$unique_id"
}

# Main function
main() {
    log_message "Starting hostname generation for i.MX93 Jaguar E-Ink board"
    
    # Check if hostname is already set to something other than default
    current_hostname=$(hostname)
    if [ "$current_hostname" != "imx93-jaguar-eink-unknown" ] && [[ "$current_hostname" == imx93-jaguar-eink-* ]]; then
        log_message "Hostname already set to: $current_hostname"
        exit 0
    fi
    
    # Generate unique identifier
    unique_id=$(generate_unique_id)
    
    if [ -z "$unique_id" ]; then
        log_message "ERROR: Could not generate unique identifier"
        exit 1
    fi
    
    # Create new hostname
    new_hostname="${MACHINE_PREFIX}-${unique_id}"
    
    # Validate hostname (max 63 characters, alphanumeric and hyphens only)
    if [ ${#new_hostname} -gt 63 ]; then
        new_hostname="${MACHINE_PREFIX}-$(echo $unique_id | tail -c 9)"
    fi
    
    # Set the hostname
    log_message "Setting hostname to: $new_hostname"
    echo "$new_hostname" > "$HOSTNAME_FILE"
    hostname "$new_hostname"
    
    # Update /etc/hosts
    if ! grep -q "$new_hostname" /etc/hosts; then
        echo "127.0.1.1    $new_hostname" >> /etc/hosts
        log_message "Added hostname to /etc/hosts"
    fi
    
    log_message "Hostname generation completed successfully"
}

main "$@"
