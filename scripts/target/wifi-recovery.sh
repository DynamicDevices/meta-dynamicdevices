#!/bin/bash
# WiFi Driver Complete Reinitialization Script
# For Maya W2 (IW612) module on i.MX93 E-Ink board
# Deploy this script to the target board

set -e

LOG_FILE="/var/log/wifi-recovery.log"
PING_TARGET="8.8.8.8"
MAX_ATTEMPTS=3

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

test_connectivity() {
    ping -c 3 -W 5 "$PING_TARGET" >/dev/null 2>&1
}

check_wifi_interface() {
    ip link show wlan0 >/dev/null 2>&1 && iwconfig wlan0 >/dev/null 2>&1
}

wifi_recovery_level1() {
    log "Level 1: Network interface reset"
    
    # Bring interface down/up
    ip link set wlan0 down 2>/dev/null || true
    sleep 1
    ip link set wlan0 up 2>/dev/null || true
    sleep 2
    
    # Restart NetworkManager
    systemctl restart NetworkManager
    sleep 5
    
    log "Level 1 complete"
}

wifi_recovery_level2() {
    log "Level 2: Driver module reload"
    
    # Remove modules in dependency order
    modprobe -r mwifiex_sdio 2>/dev/null || true
    modprobe -r mwifiex 2>/dev/null || true
    modprobe -r cfg80211 2>/dev/null || true
    
    sleep 3
    
    # Reload modules
    modprobe cfg80211
    modprobe mwifiex
    modprobe mwifiex_sdio
    
    sleep 5
    systemctl restart NetworkManager
    sleep 10
    
    log "Level 2 complete"
}

wifi_recovery_level3() {
    log "Level 3: SDIO bus reset"
    
    # Find SDIO device path
    SDIO_DEVICE=$(ls /sys/bus/sdio/devices/ | head -1)
    if [[ -n "$SDIO_DEVICE" ]]; then
        echo "$SDIO_DEVICE" > /sys/bus/sdio/drivers/mwifiex_sdio/unbind 2>/dev/null || true
        sleep 2
        echo "$SDIO_DEVICE" > /sys/bus/sdio/drivers/mwifiex_sdio/bind 2>/dev/null || true
        sleep 5
    fi
    
    systemctl restart NetworkManager
    sleep 10
    
    log "Level 3 complete"
}

wifi_recovery_level4() {
    log "Level 4: Hardware reset via GPIO"
    
    # Maya W2 reset via GPIO (if available)
    # GPIO numbers may need adjustment based on actual hardware
    if [[ -d "/sys/class/gpio/gpio26" ]]; then
        echo 0 > /sys/class/gpio/gpio26/value 2>/dev/null || true
        sleep 1
        echo 1 > /sys/class/gpio/gpio26/value 2>/dev/null || true
        sleep 3
    fi
    
    # Reset MMC host controller
    MMC_HOST="42850000.mmc"  # i.MX93 USDHC2 for WiFi
    if [[ -d "/sys/bus/platform/drivers/sdhci-esdhc-imx/$MMC_HOST" ]]; then
        echo "$MMC_HOST" > /sys/bus/platform/drivers/sdhci-esdhc-imx/unbind 2>/dev/null || true
        sleep 2
        echo "$MMC_HOST" > /sys/bus/platform/drivers/sdhci-esdhc-imx/bind 2>/dev/null || true
        sleep 5
    fi
    
    systemctl restart NetworkManager
    sleep 15
    
    log "Level 4 complete"
}

wifi_recovery_level5() {
    log "Level 5: Power cycle via MCXC143VFM"
    
    # Use eink-power-cli if available
    if command -v eink-power-cli >/dev/null 2>&1; then
        eink-power-cli wifi off 2>/dev/null || true
        sleep 3
        eink-power-cli wifi on 2>/dev/null || true
        sleep 10
    fi
    
    systemctl restart NetworkManager
    sleep 15
    
    log "Level 5 complete"
}

main() {
    log "WiFi Recovery Script Started"
    log "Testing initial connectivity..."
    
    if test_connectivity; then
        log "WiFi is working - no recovery needed"
        exit 0
    fi
    
    log "WiFi connectivity failed - starting recovery procedure"
    
    # Try each recovery level
    for level in 1 2 3 4 5; do
        log "Attempting recovery level $level"
        
        case $level in
            1) wifi_recovery_level1 ;;
            2) wifi_recovery_level2 ;;
            3) wifi_recovery_level3 ;;
            4) wifi_recovery_level4 ;;
            5) wifi_recovery_level5 ;;
        esac
        
        # Test connectivity after each level
        log "Testing connectivity after level $level"
        if test_connectivity; then
            log "SUCCESS: WiFi recovered at level $level"
            exit 0
        else
            log "Level $level failed - trying next level"
        fi
    done
    
    log "ERROR: All recovery levels failed"
    exit 1
}

# Run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

main "$@"
