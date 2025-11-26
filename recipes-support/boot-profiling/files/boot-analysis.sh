#!/bin/bash
# Boot Analysis Script for Dynamic Devices boards
# Analyzes U-Boot, kernel, and systemd boot times
# Target: 1-2 second boot time

set -e

LOG_DIR="/var/log/boot-profiling"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${LOG_DIR}/boot-analysis-${TIMESTAMP}.txt"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

echo "=== Dynamic Devices Boot Analysis Report ===" > "${REPORT_FILE}"
echo "Generated: $(date)" >> "${REPORT_FILE}"
echo "Target: 1-2 second total boot time" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

# Function to log with timestamp
log_section() {
    echo "=== $1 ===" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
}

# Function to extract time from dmesg line
extract_time() {
    echo "$1" | grep -oE '\[[[:space:]]*[0-9]+\.[0-9]+\]' | tr -d '[]' | xargs
}

log_section "BOOT TIME SUMMARY"

# Get kernel boot time from dmesg
if command -v dmesg >/dev/null 2>&1; then
    KERNEL_START=$(dmesg | head -1 | grep -oE '\[[[:space:]]*[0-9]+\.[0-9]+\]' | tr -d '[]' | xargs)
    KERNEL_END=$(dmesg | grep -E "(systemd.*Reached target.*Multi-User|login:|Reached target.*Graphical)" | tail -1 | grep -oE '\[[[:space:]]*[0-9]+\.[0-9]+\]' | tr -d '[]' | xargs)
    
    if [[ -n "$KERNEL_START" && -n "$KERNEL_END" ]]; then
        KERNEL_TIME=$(echo "$KERNEL_END - $KERNEL_START" | bc -l 2>/dev/null || echo "N/A")
        echo "Kernel boot time: ${KERNEL_TIME}s (from ${KERNEL_START}s to ${KERNEL_END}s)" >> "${REPORT_FILE}"
    fi
fi

# Get systemd boot time
if command -v systemd-analyze >/dev/null 2>&1; then
    echo "" >> "${REPORT_FILE}"
    echo "Systemd boot analysis:" >> "${REPORT_FILE}"
    systemd-analyze >> "${REPORT_FILE}" 2>/dev/null || echo "systemd-analyze not available" >> "${REPORT_FILE}"
fi

echo "" >> "${REPORT_FILE}"

log_section "U-BOOT ANALYSIS"
echo "U-Boot timing information (from dmesg):" >> "${REPORT_FILE}"
dmesg | grep -i "u-boot\|uboot" | head -10 >> "${REPORT_FILE}" 2>/dev/null || echo "No U-Boot messages found in dmesg" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

log_section "KERNEL INITIALIZATION ANALYSIS"

# Kernel initialization timing
echo "Early kernel initialization:" >> "${REPORT_FILE}"
dmesg | grep -E "\[.*\].*initcall.*returned" | head -20 >> "${REPORT_FILE}" 2>/dev/null || echo "No initcall timing found" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

# Driver initialization timing
echo "Driver initialization (first 20 entries):" >> "${REPORT_FILE}"
dmesg | grep -E "\[.*\].*driver.*probe" | head -20 >> "${REPORT_FILE}" 2>/dev/null || echo "No driver probe timing found" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

# Critical subsystem timing
echo "Critical subsystem initialization:" >> "${REPORT_FILE}"
dmesg | grep -E "\[.*\].*(MMC|SDIO|USB|GPIO|I2C|SPI|UART|ethernet)" | head -15 >> "${REPORT_FILE}" 2>/dev/null
echo "" >> "${REPORT_FILE}"

log_section "SYSTEMD SERVICE ANALYSIS"

if command -v systemd-analyze >/dev/null 2>&1; then
    echo "Slowest systemd services:" >> "${REPORT_FILE}"
    systemd-analyze blame | head -20 >> "${REPORT_FILE}" 2>/dev/null || echo "systemd-analyze blame not available" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
    
    echo "Critical path analysis:" >> "${REPORT_FILE}"
    systemd-analyze critical-chain >> "${REPORT_FILE}" 2>/dev/null || echo "systemd-analyze critical-chain not available" >> "${REPORT_FILE}"
    echo "" >> "${REPORT_FILE}"
fi

log_section "BOOT OPTIMIZATION RECOMMENDATIONS"

echo "Based on analysis, consider these optimizations:" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

# Analyze for common boot time issues
echo "1. U-Boot Optimizations:" >> "${REPORT_FILE}"
echo "   - Reduce U-Boot delay (bootdelay=0)" >> "${REPORT_FILE}"
echo "   - Minimize U-Boot environment size" >> "${REPORT_FILE}"
echo "   - Use faster storage (eMMC over SD)" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

echo "2. Kernel Optimizations:" >> "${REPORT_FILE}"
echo "   - Enable CONFIG_PRINTK_TIME for detailed timing" >> "${REPORT_FILE}"
echo "   - Use initramfs to reduce filesystem mount time" >> "${REPORT_FILE}"
echo "   - Compile drivers as built-in rather than modules" >> "${REPORT_FILE}"
echo "   - Reduce kernel log level (quiet boot)" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

echo "3. Systemd Optimizations:" >> "${REPORT_FILE}"
echo "   - Disable unnecessary services" >> "${REPORT_FILE}"
echo "   - Use systemd service dependencies efficiently" >> "${REPORT_FILE}"
echo "   - Consider systemd.show_status=false" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

echo "4. Hardware-Specific:" >> "${REPORT_FILE}"
echo "   - Optimize device tree for minimal hardware" >> "${REPORT_FILE}"
echo "   - Use fastest available clock speeds" >> "${REPORT_FILE}"
echo "   - Minimize driver initialization delays" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

log_section "DETAILED TIMING DATA"

# Full dmesg with timing for detailed analysis
echo "Complete dmesg output with timing:" >> "${REPORT_FILE}"
dmesg -T >> "${REPORT_FILE}" 2>/dev/null || dmesg >> "${REPORT_FILE}"

echo "" >> "${REPORT_FILE}"
echo "=== End of Boot Analysis Report ===" >> "${REPORT_FILE}"

# Display summary to console
echo "Boot analysis complete!"
echo "Report saved to: ${REPORT_FILE}"
echo ""
echo "Quick Summary:"
if [[ -n "$KERNEL_TIME" && "$KERNEL_TIME" != "N/A" ]]; then
    echo "  Kernel boot time: ${KERNEL_TIME}s"
fi

if command -v systemd-analyze >/dev/null 2>&1; then
    echo "  Systemd analysis:"
    systemd-analyze 2>/dev/null | head -1 || echo "    systemd-analyze failed"
fi

echo ""
echo "For detailed analysis, see: ${REPORT_FILE}"
echo "To view systemd service timing: systemd-analyze blame"
echo "To view critical path: systemd-analyze critical-chain"
