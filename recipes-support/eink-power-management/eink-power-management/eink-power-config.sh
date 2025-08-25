#!/bin/bash
# E-ink Board Power Configuration Script
# Configures optimal power settings for the e-ink display board

set -e

CONFIG_FILE="/etc/eink-power.conf"
LOG_FILE="/var/log/eink-power-config.log"

log_message() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

# Configure CPU power management
configure_cpu_power() {
    log_message "Configuring CPU power management..."
    
    # Set default governor to powersave for eink use case
    if [ -d "/sys/devices/system/cpu/cpufreq" ]; then
        echo "powersave" > /sys/devices/system/cpu/cpufreq/scaling_governor 2>/dev/null || {
            # Fallback: set for each CPU individually
            for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                if [ -f "$cpu" ]; then
                    echo "powersave" > "$cpu" || log_message "Failed to set governor for $cpu"
                fi
            done
        }
        log_message "Set CPU governor to powersave"
    fi
    
    # Enable CPU idle states
    if [ -d "/sys/devices/system/cpu/cpuidle" ]; then
        for state in /sys/devices/system/cpu/cpuidle/state*/disable; do
            if [ -f "$state" ]; then
                echo 0 > "$state" || log_message "Failed to enable idle state $state"
            fi
        done
        log_message "Enabled CPU idle states"
    fi
}

# Configure memory power management
configure_memory_power() {
    log_message "Configuring memory power management..."
    
    # Enable memory compaction for power efficiency
    if [ -f "/proc/sys/vm/compact_memory" ]; then
        echo 1 > /proc/sys/vm/compact_memory || log_message "Failed to enable memory compaction"
    fi
    
    # Reduce swappiness for eink use case (less disk activity)
    if [ -f "/proc/sys/vm/swappiness" ]; then
        echo 10 > /proc/sys/vm/swappiness || log_message "Failed to set swappiness"
        log_message "Set swappiness to 10 for reduced disk activity"
    fi
}

# Configure display/GPU power management
configure_display_power() {
    log_message "Configuring display power management..."
    
    # Disable GPU features not needed for eink
    if [ -d "/sys/class/drm" ]; then
        for panel in /sys/class/drm/*/dpms; do
            if [ -f "$panel" ]; then
                echo "Off" > "$panel" 2>/dev/null || log_message "Failed to power off display panel $panel"
            fi
        done
    fi
    
    # Set low power mode for framebuffer if available
    if [ -d "/sys/class/graphics" ]; then
        for fb in /sys/class/graphics/fb*/power/control; do
            if [ -f "$fb" ]; then
                echo "auto" > "$fb" || log_message "Failed to set auto power for $fb"
            fi
        done
        log_message "Configured framebuffer power management"
    fi
}

# Configure I/O power management
configure_io_power() {
    log_message "Configuring I/O power management..."
    
    # Enable SATA ALPM (if present)
    for host in /sys/class/scsi_host/host*/link_power_management_policy; do
        if [ -f "$host" ]; then
            echo "min_power" > "$host" || log_message "Failed to set SATA ALPM for $host"
        fi
    done
    
    # Configure USB auto-suspend
    for usb in /sys/bus/usb/devices/*/power/autosuspend; do
        if [ -f "$usb" ]; then
            echo 2 > "$usb" || log_message "Failed to set USB autosuspend for $usb"
        fi
    done
    
    for usb in /sys/bus/usb/devices/*/power/control; do
        if [ -f "$usb" ]; then
            echo "auto" > "$usb" || log_message "Failed to enable USB auto power for $usb"
        fi
    done
    
    log_message "Configured USB power management"
}

# Configure network power management
configure_network_power() {
    log_message "Configuring network power management..."
    
    # Configure WiFi power management
    for wifi in /sys/class/net/wl*/device/power/control; do
        if [ -f "$wifi" ]; then
            echo "auto" > "$wifi" || log_message "Failed to configure WiFi power management"
        fi
    done
    
    # Enable ethernet power management
    for eth in /sys/class/net/eth*/device/power/control; do
        if [ -f "$eth" ]; then
            echo "auto" > "$eth" || log_message "Failed to configure Ethernet power management"
        fi
    done
    
    log_message "Configured network power management"
}

# Configure MCXC143VFM power controller
configure_power_controller() {
    log_message "Configuring MCXC143VFM power controller..."
    
    # The MCXC143VFM is an external power management microcontroller
    # It controls WiFi module power and system power states
    
    # Configure GPIO pins for power controller interface
    if [ -d "/sys/class/gpio" ]; then
        # WiFi reset/power control (GPIO4_26) - IMX93: 608 + 26 = 634
        if [ ! -d "/sys/class/gpio/gpio634" ]; then
            echo 634 > /sys/class/gpio/export 2>/dev/null || log_message "Failed to export WiFi power GPIO"
        fi
        
        # BT reset control (GPIO4_24) - IMX93: 608 + 24 = 632
        if [ ! -d "/sys/class/gpio/gpio632" ]; then
            echo 632 > /sys/class/gpio/export 2>/dev/null || log_message "Failed to export BT power GPIO"
        fi
        
        log_message "Configured power controller GPIO interfaces"
    fi
}

# Create power management configuration file
create_config_file() {
    log_message "Creating power management configuration file..."
    
    cat > "$CONFIG_FILE" << EOF
# E-ink Board Power Management Configuration
# Generated on $(date)

# CPU Power Management
CPU_GOVERNOR=powersave
CPU_IDLE_STATES=enabled

# Memory Management
SWAPPINESS=10
MEMORY_COMPACTION=enabled

# Network Power Management
WIFI_POWER_SAVE=enabled
ETHERNET_POWER_SAVE=enabled

# USB Power Management
USB_AUTOSUSPEND=2
USB_CONTROL=auto

# Display Power Management
GPU_POWER_SAVE=enabled
FRAMEBUFFER_POWER=auto

# Suspend Configuration
SUSPEND_MODE=s2idle
WAKEUP_SOURCES=usb,wifi-magic
# WiFi wake configured for magic packets only - prevents unwanted wakeups from network scans/broadcasts  
# Allows intentional remote wake via Wake-on-LAN while maintaining power efficiency for eink displays
# Magic packet format: 6 bytes of 0xFF followed by 16 repetitions of target MAC address

# MCXC143VFM Controller
POWER_CONTROLLER=enabled
WIFI_POWER_GPIO=634
BT_POWER_GPIO=632

EOF

    log_message "Created configuration file: $CONFIG_FILE"
}

# Apply power optimizations
apply_power_optimizations() {
    log_message "Applying power optimizations..."
    
    # Optimize kernel parameters for power efficiency
    if [ -f "/proc/sys/kernel/nmi_watchdog" ]; then
        echo 0 > /proc/sys/kernel/nmi_watchdog || log_message "Failed to disable NMI watchdog"
    fi
    
    # Disable unnecessary kernel features
    if [ -f "/proc/sys/kernel/printk" ]; then
        echo "3 4 1 3" > /proc/sys/kernel/printk || log_message "Failed to reduce kernel logging"
    fi
    
    # Configure I/O scheduler for power efficiency
    for queue in /sys/block/*/queue/scheduler; do
        if [ -f "$queue" ]; then
            echo "noop" > "$queue" 2>/dev/null || echo "none" > "$queue" 2>/dev/null || log_message "Failed to set I/O scheduler for $queue"
        fi
    done
    
    log_message "Applied kernel power optimizations"
}

# Main configuration function
main() {
    log_message "Starting E-ink board power configuration..."
    
    configure_cpu_power
    configure_memory_power
    configure_display_power
    configure_io_power
    configure_network_power
    configure_power_controller
    create_config_file
    apply_power_optimizations
    
    log_message "E-ink board power configuration completed successfully"
    
    # Display current power status
    log_message "Current power status:"
    if command -v powertop >/dev/null 2>&1; then
        powertop --auto-tune 2>/dev/null || log_message "Powertop auto-tune failed"
    fi
}

main "$@"
