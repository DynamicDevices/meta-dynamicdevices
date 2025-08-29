#!/bin/bash
# Manual boot profiling script for Dynamic Devices boards
# Usage: profile-boot.sh [--live] [--save-plot]

set -e

LIVE_MODE=false
SAVE_PLOT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --live)
            LIVE_MODE=true
            shift
            ;;
        --save-plot)
            SAVE_PLOT=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--live] [--save-plot]"
            echo "  --live      Show live systemd boot analysis"
            echo "  --save-plot Save systemd boot plot (requires systemd-analyze plot)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=== Dynamic Devices Boot Profiling Tool ==="
echo "Target: 1-2 second boot time"
echo ""

# Quick boot time summary
echo "=== QUICK BOOT SUMMARY ==="
if command -v systemd-analyze >/dev/null 2>&1; then
    echo "Overall boot time:"
    systemd-analyze 2>/dev/null || echo "systemd-analyze failed"
    echo ""
    
    echo "Top 10 slowest services:"
    systemd-analyze blame 2>/dev/null | head -10 || echo "systemd-analyze blame failed"
    echo ""
    
    echo "Critical path:"
    systemd-analyze critical-chain 2>/dev/null || echo "systemd-analyze critical-chain failed"
    echo ""
else
    echo "systemd-analyze not available"
fi

# Kernel boot analysis from dmesg
echo "=== KERNEL BOOT ANALYSIS ==="
if command -v dmesg >/dev/null 2>&1; then
    # Find kernel start and key milestones
    KERNEL_START=$(dmesg | head -1 | grep -oE '\[[[:space:]]*[0-9]+\.[0-9]+\]' | tr -d '[]' | xargs)
    
    echo "Kernel initialization milestones:"
    echo "  Start: ${KERNEL_START}s"
    
    # Key kernel milestones
    dmesg | grep -E "\[.*\].*(Freeing unused kernel|Freeing init memory|Run /sbin/init|systemd.*running)" | while read -r line; do
        TIME=$(echo "$line" | grep -oE '\[[[:space:]]*[0-9]+\.[0-9]+\]' | tr -d '[]' | xargs)
        MSG=$(echo "$line" | sed 's/\[.*\]//' | xargs)
        echo "  ${TIME}s: $MSG"
    done
    echo ""
    
    echo "Driver initialization timing (top 10 slowest):"
    dmesg | grep -E "\[.*\].*took.*ms" | sort -k2 -nr | head -10 || echo "No driver timing information found"
    echo ""
else
    echo "dmesg not available"
fi

# Hardware-specific analysis
echo "=== HARDWARE-SPECIFIC ANALYSIS ==="
echo "Storage performance:"
if [[ -e /sys/block/mmcblk0/queue/scheduler ]]; then
    echo "  eMMC scheduler: $(cat /sys/block/mmcblk0/queue/scheduler 2>/dev/null || echo 'unknown')"
fi
if [[ -e /sys/block/mmcblk1/queue/scheduler ]]; then
    echo "  SD card scheduler: $(cat /sys/block/mmcblk1/queue/scheduler 2>/dev/null || echo 'unknown')"
fi

echo ""
echo "Memory info:"
grep -E "(MemTotal|MemFree|MemAvailable)" /proc/meminfo 2>/dev/null || echo "Memory info not available"

echo ""
echo "CPU info:"
grep -E "(processor|model name|cpu MHz)" /proc/cpuinfo | head -8 2>/dev/null || echo "CPU info not available"

# Live mode - continuous monitoring
if [[ "$LIVE_MODE" == "true" ]]; then
    echo ""
    echo "=== LIVE MONITORING MODE ==="
    echo "Press Ctrl+C to stop..."
    echo ""
    
    while true; do
        clear
        echo "=== Live Boot Analysis - $(date) ==="
        echo ""
        
        if command -v systemd-analyze >/dev/null 2>&1; then
            systemd-analyze 2>/dev/null || echo "systemd-analyze failed"
            echo ""
            echo "Active services:"
            systemctl list-units --type=service --state=active --no-pager | head -10
        fi
        
        sleep 5
    done
fi

# Save plot if requested
if [[ "$SAVE_PLOT" == "true" ]]; then
    echo ""
    echo "=== SAVING BOOT PLOT ==="
    PLOT_FILE="/var/log/boot-profiling/boot-plot-$(date +%Y%m%d_%H%M%S).svg"
    
    if command -v systemd-analyze >/dev/null 2>&1; then
        mkdir -p "$(dirname "$PLOT_FILE")"
        if systemd-analyze plot > "$PLOT_FILE" 2>/dev/null; then
            echo "Boot plot saved to: $PLOT_FILE"
        else
            echo "Failed to generate boot plot"
        fi
    else
        echo "systemd-analyze not available for plotting"
    fi
fi

echo ""
echo "=== OPTIMIZATION SUGGESTIONS ==="
echo "For 1-2s boot target, consider:"
echo "1. Reduce U-Boot delay (bootdelay=0)"
echo "2. Use initramfs for faster rootfs access"
echo "3. Compile critical drivers into kernel (not as modules)"
echo "4. Disable unnecessary systemd services"
echo "5. Use 'quiet' kernel parameter to reduce console output"
echo "6. Optimize device tree for minimal hardware configuration"
echo ""
echo "Run 'boot-analysis.sh' for detailed analysis and report generation."
