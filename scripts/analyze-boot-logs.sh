#!/bin/bash
# Boot Log Analysis Tool for Dynamic Devices Boards
# Processes serial boot logs to extract detailed timing information
# Usage: ./analyze-boot-logs.sh [--log-dir ./boot-logs] [--latest] [--compare]

set -e

# Default configuration
DEFAULT_LOG_DIR="./boot-logs"
DEFAULT_OUTPUT_DIR="./boot-analysis"

# Parse command line arguments
LOG_DIR="$DEFAULT_LOG_DIR"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
ANALYZE_LATEST=false
COMPARE_MODE=false
SPECIFIC_LOG=""

show_help() {
    cat << EOF
Boot Log Analysis Tool for Dynamic Devices Boards

Usage: $0 [OPTIONS] [LOG_FILE]

OPTIONS:
    -l, --log-dir DIR       Log directory to search (default: $DEFAULT_LOG_DIR)
    -o, --output-dir DIR    Output directory for analysis (default: $DEFAULT_OUTPUT_DIR)
    --latest                Analyze the most recent log automatically
    --compare               Compare multiple boot logs for trends
    -h, --help              Show this help

EXAMPLES:
    # Analyze latest boot log
    $0 --latest

    # Analyze specific log file
    $0 ./boot-logs/boot_20240115_143022_timing.log

    # Compare all logs in directory
    $0 --compare

    # Custom directories
    $0 --log-dir ./my-logs --output-dir ./my-analysis --latest

The script will generate:
1. Detailed timing breakdown
2. Boot phase analysis (U-Boot, Kernel, Systemd)
3. Service timing analysis
4. Optimization recommendations
5. Comparison charts (in compare mode)

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--log-dir)
            LOG_DIR="$2"
            shift 2
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --latest)
            ANALYZE_LATEST=true
            shift
            ;;
        --compare)
            COMPARE_MODE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            SPECIFIC_LOG="$1"
            shift
            ;;
    esac
done

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to find timing logs
find_timing_logs() {
    find "$LOG_DIR" -name "*_timing.log" -type f 2>/dev/null | sort
}

# Function to get latest timing log
get_latest_log() {
    find_timing_logs | tail -1
}

# Function to extract boot phases from a timing log
analyze_boot_phases() {
    local log_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$log_file" ]]; then
        echo "Error: Log file not found: $log_file"
        return 1
    fi
    
    echo "=== Boot Phase Analysis ===" > "$output_file"
    echo "Log file: $log_file" >> "$output_file"
    echo "Generated: $(date)" >> "$output_file"
    echo "" >> "$output_file"
    
    # Extract key timing points
    local uboot_start=$(grep -E "\[.*\].*U-Boot.*" "$log_file" | head -1 | sed -E 's/.*\[([0-9.]+)\].*/\1/' 2>/dev/null || echo "")
    local kernel_start=$(grep -E "\[.*\].*Linux version" "$log_file" | head -1 | sed -E 's/.*\[([0-9.]+)\].*/\1/' 2>/dev/null || echo "")
    local kernel_end=$(grep -E "\[.*\].*Freeing unused kernel" "$log_file" | head -1 | sed -E 's/.*\[([0-9.]+)\].*/\1/' 2>/dev/null || echo "")
    local systemd_start=$(grep -E "\[.*\].*systemd.*version" "$log_file" | head -1 | sed -E 's/.*\[([0-9.]+)\].*/\1/' 2>/dev/null || echo "")
    local boot_complete=$(grep -E "\[.*\].*(login:|Welcome to|systemd.*Startup finished)" "$log_file" | tail -1 | sed -E 's/.*\[([0-9.]+)\].*/\1/' 2>/dev/null || echo "")
    
    echo "=== Key Timing Points ===" >> "$output_file"
    [[ -n "$uboot_start" ]] && echo "U-Boot start: ${uboot_start}s" >> "$output_file"
    [[ -n "$kernel_start" ]] && echo "Kernel start: ${kernel_start}s" >> "$output_file"
    [[ -n "$kernel_end" ]] && echo "Kernel end: ${kernel_end}s" >> "$output_file"
    [[ -n "$systemd_start" ]] && echo "Systemd start: ${systemd_start}s" >> "$output_file"
    [[ -n "$boot_complete" ]] && echo "Boot complete: ${boot_complete}s" >> "$output_file"
    echo "" >> "$output_file"
    
    # Calculate phase durations
    echo "=== Phase Durations ===" >> "$output_file"
    
    if [[ -n "$kernel_start" && -n "$uboot_start" ]]; then
        local uboot_duration=$(echo "$kernel_start - $uboot_start" | bc -l 2>/dev/null || echo "")
        [[ -n "$uboot_duration" ]] && echo "U-Boot phase: ${uboot_duration}s" >> "$output_file"
    fi
    
    if [[ -n "$kernel_end" && -n "$kernel_start" ]]; then
        local kernel_duration=$(echo "$kernel_end - $kernel_start" | bc -l 2>/dev/null || echo "")
        [[ -n "$kernel_duration" ]] && echo "Kernel phase: ${kernel_duration}s" >> "$output_file"
    fi
    
    if [[ -n "$boot_complete" && -n "$systemd_start" ]]; then
        local systemd_duration=$(echo "$boot_complete - $systemd_start" | bc -l 2>/dev/null || echo "")
        [[ -n "$systemd_duration" ]] && echo "Systemd phase: ${systemd_duration}s" >> "$output_file"
    fi
    
    if [[ -n "$boot_complete" && -n "$uboot_start" ]]; then
        local total_duration=$(echo "$boot_complete - $uboot_start" | bc -l 2>/dev/null || echo "")
        [[ -n "$total_duration" ]] && echo "Total boot time: ${total_duration}s" >> "$output_file"
    fi
    
    echo "" >> "$output_file"
    
    # Extract service timing (if available)
    echo "=== Service Analysis ===" >> "$output_file"
    grep -E "\[.*\].*systemd.*Started" "$log_file" | head -10 >> "$output_file" 2>/dev/null || echo "No systemd service start messages found" >> "$output_file"
    
    echo "" >> "$output_file"
    
    # Extract driver timing
    echo "=== Driver Timing ===" >> "$output_file"
    grep -E "\[.*\].*took.*ms" "$log_file" | head -10 >> "$output_file" 2>/dev/null || echo "No driver timing messages found" >> "$output_file"
    
    echo "" >> "$output_file"
    
    # Generate recommendations
    echo "=== Optimization Recommendations ===" >> "$output_file"
    
    if [[ -n "$total_duration" ]]; then
        if (( $(echo "$total_duration > 5.0" | bc -l 2>/dev/null || echo "0") )); then
            echo "❌ SLOW BOOT (${total_duration}s) - Immediate optimization needed:" >> "$output_file"
            echo "  - Check for stuck services or drivers" >> "$output_file"
            echo "  - Enable boot profiling for detailed analysis" >> "$output_file"
            echo "  - Consider hardware issues" >> "$output_file"
        elif (( $(echo "$total_duration > 2.0" | bc -l 2>/dev/null || echo "0") )); then
            echo "⚠️  MODERATE BOOT (${total_duration}s) - Optimization recommended:" >> "$output_file"
            echo "  - Disable unnecessary services" >> "$output_file"
            echo "  - Optimize U-Boot configuration" >> "$output_file"
            echo "  - Build critical drivers into kernel" >> "$output_file"
        elif (( $(echo "$total_duration > 1.5" | bc -l 2>/dev/null || echo "0") )); then
            echo "✅ GOOD BOOT (${total_duration}s) - Minor optimizations possible:" >> "$output_file"
            echo "  - Fine-tune service dependencies" >> "$output_file"
            echo "  - Reduce console output" >> "$output_file"
        else
            echo "✅ EXCELLENT BOOT (${total_duration}s) - Target achieved!" >> "$output_file"
            echo "  - Boot time is optimal for embedded system" >> "$output_file"
        fi
    else
        echo "⚠️  Could not determine total boot time from log" >> "$output_file"
        echo "  - Check log format and boot completion markers" >> "$output_file"
    fi
    
    echo "" >> "$output_file"
    echo "Analysis complete. Review recommendations above." >> "$output_file"
}

# Function to compare multiple boot logs
compare_boot_logs() {
    local comparison_file="$OUTPUT_DIR/boot_comparison_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "=== Boot Time Comparison Analysis ===" > "$comparison_file"
    echo "Generated: $(date)" >> "$comparison_file"
    echo "" >> "$comparison_file"
    
    local logs=($(find_timing_logs))
    
    if [[ ${#logs[@]} -eq 0 ]]; then
        echo "No timing logs found in $LOG_DIR" >> "$comparison_file"
        return 1
    fi
    
    echo "Found ${#logs[@]} boot logs:" >> "$comparison_file"
    
    # Extract boot times from all logs
    local boot_times=()
    local log_names=()
    
    for log in "${logs[@]}"; do
        local boot_time=$(grep -E "\[.*\].*(login:|Welcome to|systemd.*Startup finished)" "$log" | tail -1 | sed -E 's/.*\[([0-9.]+)\].*/\1/' 2>/dev/null || echo "")
        local log_name=$(basename "$log" | sed 's/_timing\.log$//')
        
        if [[ -n "$boot_time" ]]; then
            boot_times+=("$boot_time")
            log_names+=("$log_name")
            echo "  $log_name: ${boot_time}s" >> "$comparison_file"
        else
            echo "  $log_name: Could not determine boot time" >> "$comparison_file"
        fi
    done
    
    echo "" >> "$comparison_file"
    
    # Calculate statistics
    if [[ ${#boot_times[@]} -gt 0 ]]; then
        local min_time=$(printf '%s\n' "${boot_times[@]}" | sort -n | head -1)
        local max_time=$(printf '%s\n' "${boot_times[@]}" | sort -n | tail -1)
        local avg_time=$(echo "scale=3; ($(IFS=+; echo "${boot_times[*]}")) / ${#boot_times[@]}" | bc -l 2>/dev/null || echo "")
        
        echo "=== Statistics ===" >> "$comparison_file"
        echo "Fastest boot: ${min_time}s" >> "$comparison_file"
        echo "Slowest boot: ${max_time}s" >> "$comparison_file"
        [[ -n "$avg_time" ]] && echo "Average boot: ${avg_time}s" >> "$comparison_file"
        
        local variation=$(echo "scale=3; $max_time - $min_time" | bc -l 2>/dev/null || echo "")
        [[ -n "$variation" ]] && echo "Variation: ${variation}s" >> "$comparison_file"
        
        echo "" >> "$comparison_file"
        
        # Trend analysis
        echo "=== Trend Analysis ===" >> "$comparison_file"
        if (( $(echo "$variation > 1.0" | bc -l 2>/dev/null || echo "0") )); then
            echo "⚠️  HIGH VARIATION (${variation}s) - Inconsistent boot times" >> "$comparison_file"
            echo "  - Check for intermittent hardware issues" >> "$comparison_file"
            echo "  - Look for network timeout variations" >> "$comparison_file"
        elif (( $(echo "$variation > 0.5" | bc -l 2>/dev/null || echo "0") )); then
            echo "⚠️  MODERATE VARIATION (${variation}s) - Some inconsistency" >> "$comparison_file"
            echo "  - Monitor for patterns in slow boots" >> "$comparison_file"
        else
            echo "✅ CONSISTENT BOOT TIMES (${variation}s variation)" >> "$comparison_file"
            echo "  - Boot performance is stable" >> "$comparison_file"
        fi
    fi
    
    echo "" >> "$comparison_file"
    echo "Comparison analysis saved to: $comparison_file"
    cat "$comparison_file"
}

# Main execution logic
echo "=== Boot Log Analysis Tool ==="

if [[ "$COMPARE_MODE" == "true" ]]; then
    echo "Running comparison analysis..."
    compare_boot_logs
    exit 0
fi

# Determine which log to analyze
if [[ -n "$SPECIFIC_LOG" ]]; then
    LOG_TO_ANALYZE="$SPECIFIC_LOG"
elif [[ "$ANALYZE_LATEST" == "true" ]]; then
    LOG_TO_ANALYZE=$(get_latest_log)
    if [[ -z "$LOG_TO_ANALYZE" ]]; then
        echo "Error: No timing logs found in $LOG_DIR"
        exit 1
    fi
    echo "Analyzing latest log: $LOG_TO_ANALYZE"
else
    # Interactive selection
    local logs=($(find_timing_logs))
    if [[ ${#logs[@]} -eq 0 ]]; then
        echo "Error: No timing logs found in $LOG_DIR"
        echo "Run serial-boot-logger.sh first to capture boot logs"
        exit 1
    fi
    
    echo "Available timing logs:"
    for i in "${!logs[@]}"; do
        echo "  $((i+1)). $(basename "${logs[i]}")"
    done
    
    echo -n "Select log to analyze (1-${#logs[@]}): "
    read -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#logs[@]} ]]; then
        LOG_TO_ANALYZE="${logs[$((selection-1))]}"
    else
        echo "Invalid selection"
        exit 1
    fi
fi

# Generate analysis
if [[ -n "$LOG_TO_ANALYZE" ]]; then
    echo "Analyzing: $LOG_TO_ANALYZE"
    
    local analysis_file="$OUTPUT_DIR/analysis_$(basename "$LOG_TO_ANALYZE" .log)_$(date +%Y%m%d_%H%M%S).txt"
    
    analyze_boot_phases "$LOG_TO_ANALYZE" "$analysis_file"
    
    echo ""
    echo "Analysis complete!"
    echo "Report saved to: $analysis_file"
    echo ""
    echo "=== Quick Summary ==="
    cat "$analysis_file"
else
    echo "Error: No log file specified"
    show_help
    exit 1
fi
