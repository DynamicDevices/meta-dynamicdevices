#!/bin/bash
# Setup Wake-on-WLAN for eink board
# This script configures WiFi to wake only on magic packets

set -e

LOG_FILE="/var/log/setup-wowlan.log"

log_message() {
    echo "$(date): $1" | tee -a "$LOG_FILE"
}

# Find the correct WiFi PHY
find_wifi_phy() {
    # Look for mwiphy0 first, then fallback to other phys
    if iw phy mwiphy0 info >/dev/null 2>&1; then
        echo "mwiphy0"
        return 0
    fi
    
    # Fallback to first available phy with WoWLAN support
    for phy in $(iw phy | grep '^Wiphy' | cut -d' ' -f2); do
        if iw phy "$phy" info | grep -q "WoWLAN support"; then
            echo "$phy"
            return 0
        fi
    done
    
    return 1
}

# Configure WoWLAN magic packet wake
setup_wowlan() {
    log_message "Setting up Wake-on-WLAN..."
    
    WIFI_PHY=$(find_wifi_phy)
    if [ $? -ne 0 ] || [ -z "$WIFI_PHY" ]; then
        log_message "ERROR: No WiFi PHY with WoWLAN support found"
        return 1
    fi
    
    log_message "Found WiFi PHY: $WIFI_PHY"
    
    # Disable any existing WoWLAN configuration
    iw phy "$WIFI_PHY" wowlan disable 2>/dev/null || true
    
    # Enable magic packet wake only
    if iw phy "$WIFI_PHY" wowlan enable magic-packet; then
        log_message "WoWLAN magic packet wake enabled on $WIFI_PHY"
        
        # Verify configuration
        if iw phy "$WIFI_PHY" wowlan show | grep -q "wake up on magic packet"; then
            log_message "WoWLAN configuration verified successfully"
            return 0
        else
            log_message "ERROR: WoWLAN configuration verification failed"
            return 1
        fi
    else
        log_message "ERROR: Failed to enable WoWLAN magic packet wake"
        return 1
    fi
}

# Main execution
main() {
    log_message "Starting WoWLAN setup..."
    
    if setup_wowlan; then
        log_message "WoWLAN setup completed successfully"
        exit 0
    else
        log_message "WoWLAN setup failed"
        exit 1
    fi
}

main "$@"
