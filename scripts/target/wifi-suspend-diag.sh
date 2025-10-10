#!/bin/bash
# WiFi Suspend/Resume Diagnostic Script
# Captures detailed state before/after suspend for analysis
# Deploy this script to the target board

DIAG_DIR="/tmp/wifi-suspend-diag"
mkdir -p "$DIAG_DIR"

capture_wifi_state() {
    local phase="$1"
    local state_dir="$DIAG_DIR/$phase"
    mkdir -p "$state_dir"
    
    echo "=== Capturing WiFi state: $phase ===" | tee "$state_dir/summary.txt"
    
    # Network interfaces
    ip link show > "$state_dir/ip_link.txt" 2>&1
    ip addr show > "$state_dir/ip_addr.txt" 2>&1
    ip route show > "$state_dir/ip_route.txt" 2>&1
    
    # WiFi specific
    iwconfig > "$state_dir/iwconfig.txt" 2>&1
    iw dev wlan0 info > "$state_dir/iw_info.txt" 2>&1 || true
    iw dev wlan0 scan dump > "$state_dir/iw_scan.txt" 2>&1 || true
    
    # Driver/module status
    lsmod | grep -E 'mwifiex|cfg80211|mmc' > "$state_dir/modules.txt" 2>&1
    
    # SDIO bus
    ls -la /sys/bus/sdio/devices/ > "$state_dir/sdio_devices.txt" 2>&1
    find /sys/bus/sdio/devices/ -name "modalias" -exec cat {} \; > "$state_dir/sdio_modalias.txt" 2>&1
    
    # MMC/SDIO host
    ls -la /sys/class/mmc_host/ > "$state_dir/mmc_hosts.txt" 2>&1
    find /sys/class/mmc_host/ -name "mmc*" -exec cat {}/*/uevent \; > "$state_dir/mmc_uevent.txt" 2>&1 || true
    
    # Power management
    cat /sys/class/net/wlan0/device/power/control > "$state_dir/power_control.txt" 2>&1 || true
    cat /sys/class/net/wlan0/device/power/runtime_status > "$state_dir/power_runtime_status.txt" 2>&1 || true
    
    # Kernel messages (last 50 lines)
    dmesg | tail -50 > "$state_dir/dmesg_tail.txt" 2>&1
    
    # Connectivity test
    ping -c 3 -W 2 8.8.8.8 > "$state_dir/ping_test.txt" 2>&1 || echo "PING FAILED" >> "$state_dir/ping_test.txt"
    
    echo "State captured to: $state_dir"
}

# Usage: wifi-suspend-diag.sh [pre|post|compare]
case "${1:-help}" in
    pre)
        capture_wifi_state "pre_suspend"
        echo "Pre-suspend state captured. Now run: sudo rtcwake -m freeze -s 10"
        ;;
    post)
        capture_wifi_state "post_resume"
        echo "Post-resume state captured. Run 'wifi-suspend-diag.sh compare' to analyze differences."
        ;;
    compare)
        echo "=== WiFi Suspend/Resume Comparison ==="
        for file in ip_link.txt iwconfig.txt modules.txt sdio_devices.txt ping_test.txt; do
            if [[ -f "$DIAG_DIR/pre_suspend/$file" && -f "$DIAG_DIR/post_resume/$file" ]]; then
                echo ""
                echo "=== Comparing $file ==="
                diff -u "$DIAG_DIR/pre_suspend/$file" "$DIAG_DIR/post_resume/$file" || true
            fi
        done
        
        echo ""
        echo "=== Key Diagnostics ==="
        echo "Pre-suspend ping:"
        tail -1 "$DIAG_DIR/pre_suspend/ping_test.txt" 2>/dev/null || echo "No pre-suspend data"
        echo "Post-resume ping:"
        tail -1 "$DIAG_DIR/post_resume/ping_test.txt" 2>/dev/null || echo "No post-resume data"
        
        echo ""
        echo "Full diagnostic data available in: $DIAG_DIR"
        ;;
    clean)
        rm -rf "$DIAG_DIR"
        echo "Diagnostic data cleared"
        ;;
    *)
        echo "Usage: $0 [pre|post|compare|clean]"
        echo "  pre     - Capture state before suspend"
        echo "  post    - Capture state after resume" 
        echo "  compare - Compare pre/post states"
        echo "  clean   - Remove diagnostic data"
        ;;
esac
