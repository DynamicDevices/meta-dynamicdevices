#!/bin/sh

# =============================================================================
# AEC Pipeline Health Monitor
# =============================================================================
# This script monitors the health of the AEC pipeline without restarting it.
# It performs preventive maintenance and provides early warning of issues.
#
# Features:
# - Non-destructive health checks
# - Memory usage monitoring
# - Audio flow verification
# - ALSA state maintenance
# - System resource monitoring
# - Buffer status monitoring
# =============================================================================

# Configuration
MONITOR_INTERVAL=60               # Check every 60 seconds
MEMORY_THRESHOLD=100000           # 100MB RSS threshold
LOG_FILE="/tmp/aec_monitor.log"
AUDIO_TEST_DURATION=1             # 1 second test recording

# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check if pipeline process is running
check_pipeline_running() {
    if [ -n "$PIPELINE_PID" ] && kill -0 "$PIPELINE_PID" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to test audio capture functionality
test_audio_capture() {
    local test_file="/tmp/audio_test_$(date +%s).wav"
    
    # Test default capture device
    if arecord -D default -f S16_LE -r 16000 -c 1 -d $AUDIO_TEST_DURATION "$test_file" 2>/dev/null; then
        # Check if file has actual audio data (not just silence)
        local file_size=$(stat -c%s "$test_file" 2>/dev/null || echo 0)
        rm -f "$test_file"
        
        if [ "$file_size" -gt 1000 ]; then  # At least 1KB of audio data
            return 0
        else
            log_message "WARNING: Audio capture test produced empty/small file"
            return 1
        fi
    else
        log_message "ERROR: Audio capture test failed"
        return 1
    fi
}

# Function to test audio playback functionality
test_audio_playback() {
    # Generate a brief test tone and play it
    local test_file="/tmp/playback_test_$(date +%s).wav"
    
    # Create a 1-second 440Hz sine wave
    if command -v sox >/dev/null 2>&1; then
        sox -n -r 48000 -c 2 "$test_file" synth 0.1 sine 440 vol 0.1 2>/dev/null
        if aplay -D default "$test_file" 2>/dev/null; then
            rm -f "$test_file"
            return 0
        else
            log_message "WARNING: Audio playback test failed"
            rm -f "$test_file"
            return 1
        fi
    else
        # Skip playback test if sox is not available
        log_message "INFO: Skipping playback test (sox not available)"
        return 0
    fi
}

# Function to check memory usage of the pipeline
check_memory_usage() {
    if [ -n "$PIPELINE_PID" ]; then
        local mem_info=$(ps -o pid,vsz,rss,comm -p "$PIPELINE_PID" 2>/dev/null | tail -1)
        if [ -n "$mem_info" ]; then
            local rss=$(echo "$mem_info" | awk '{print $3}')
            local vsz=$(echo "$mem_info" | awk '{print $2}')
            
            log_message "INFO: Pipeline memory usage - RSS: ${rss}KB, VSZ: ${vsz}KB"
            
            if [ "$rss" -gt "$MEMORY_THRESHOLD" ]; then
                log_message "WARNING: High memory usage detected - RSS: ${rss}KB"
                return 1
            fi
        fi
    fi
    return 0
}

# Function to check system resources
check_system_resources() {
    # Check CPU load
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | sed 's/^[ \t]*//')
    local cpu_cores=$(nproc)
    
    # Use simple comparison instead of bc for compatibility
    if [ -n "$load_avg" ] && [ -n "$cpu_cores" ]; then
        # Convert to integer for comparison (multiply by 100)
        local load_int=$(echo "$load_avg * 100" | awk '{printf "%.0f", $1}')
        local threshold_int=$(echo "$cpu_cores * 80" | awk '{printf "%.0f", $1}')
        
        if [ "$load_int" -gt "$threshold_int" ]; then
            log_message "WARNING: High CPU load detected - ${load_avg}"
        fi
    fi
    
    # Check memory usage
    local mem_info=$(free | grep '^Mem:')
    local mem_total=$(echo "$mem_info" | awk '{print $2}')
    local mem_used=$(echo "$mem_info" | awk '{print $3}')
    
    # Use awk for percentage calculation instead of bc
    if [ -n "$mem_total" ] && [ "$mem_total" -gt 0 ]; then
        local mem_percent=$(echo "$mem_used $mem_total" | awk '{printf "%.1f", $1 * 100 / $2}')
        local mem_percent_int=$(echo "$mem_percent" | cut -d'.' -f1)
        
        if [ "$mem_percent_int" -gt 90 ]; then
            log_message "WARNING: High system memory usage - ${mem_percent}%"
        fi
    fi
    
    # Check disk space for temp files
    local disk_usage=$(df /tmp | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        log_message "WARNING: High disk usage in /tmp - ${disk_usage}%"
    fi
}

# Function to perform non-destructive ALSA maintenance
maintain_alsa_state() {
    log_message "INFO: Performing ALSA state maintenance"
    
    # Clean up old temporary audio files
    find /tmp -name "*.wav" -type f -mtime +1 -delete 2>/dev/null
    find /tmp -name "gst_*.dot" -type f -mtime +1 -delete 2>/dev/null
    
    # Check for stale shared memory segments
    local stale_segments=$(ipcs -m | grep "$(id -u)" | wc -l)
    if [ "$stale_segments" -gt 10 ]; then
        log_message "WARNING: Many shared memory segments detected ($stale_segments)"
    fi
    
    # Verify mixer settings are correct
    if command -v amixer >/dev/null 2>&1; then
        # Check if PCM volume is reasonable
        local pcm_vol=$(amixer -c 0 sget 'PCM' 2>/dev/null | grep -o '[0-9]*%' | head -1 | sed 's/%//')
        if [ -n "$pcm_vol" ] && [ "$pcm_vol" -lt 20 ]; then
            log_message "WARNING: PCM volume is very low ($pcm_vol%)"
        fi
    fi
}

# Function to check buffer status using GStreamer tools
check_buffer_status() {
    if [ -n "$PIPELINE_PID" ]; then
        log_message "INFO: Checking pipeline buffer status"
        
        # Use gst-stats to get buffer statistics if available
        if command -v gst-stats-1.0 >/dev/null 2>&1; then
            local stats_output=$(timeout 5 gst-stats-1.0 --pid "$PIPELINE_PID" 2>/dev/null)
            if [ -n "$stats_output" ]; then
                log_message "INFO: Pipeline statistics:"
                echo "$stats_output" | grep -E "(buffer|queue|fps|cpu)" | while read -r line; do
                    log_message "  $line"
                done
            fi
        fi
        
        # Check /proc/PID/fd for file descriptors (GStreamer uses various FDs)
        local proc_fd_dir="/proc/$PIPELINE_PID/fd"
        if [ -d "$proc_fd_dir" ]; then
            local total_fds=$(ls -1 "$proc_fd_dir" 2>/dev/null | wc -l)
            local socket_count=$(ls -l "$proc_fd_dir" 2>/dev/null | grep -c "socket:")
            local dev_snd_count=$(ls -l "$proc_fd_dir" 2>/dev/null | grep -c "/dev/snd/")
            local anon_inode_count=$(ls -l "$proc_fd_dir" 2>/dev/null | grep -c "anon_inode:")
            
            log_message "INFO: Pipeline file descriptors:"
            log_message "  Total FDs: $total_fds"
            log_message "  Sockets: $socket_count"
            log_message "  ALSA devices: $dev_snd_count"
            log_message "  Anonymous inodes: $anon_inode_count"
            
            # Show actual ALSA device connections
            if [ "$dev_snd_count" -gt 0 ]; then
                local alsa_devices=$(ls -l "$proc_fd_dir" 2>/dev/null | grep "/dev/snd/" | awk '{print $NF}' | sort -u)
                log_message "  Connected ALSA devices:"
                echo "$alsa_devices" | while read -r device; do
                    log_message "    $device"
                done
            fi
        fi
        
        # Check for queue buffer levels using GStreamer debug
        local debug_files="/tmp/gstreamer_debug.log /tmp/gstreamer_production.log"
        for debug_file in $debug_files; do
            if [ -f "$debug_file" ]; then
                # Look for queue buffer level information
                local queue_info=$(tail -50 "$debug_file" 2>/dev/null | grep -i "queue.*current-level")
                if [ -n "$queue_info" ]; then
                    log_message "INFO: Recent queue levels from $(basename "$debug_file"):"
                    echo "$queue_info" | tail -3 | while read -r line; do
                        log_message "  $line"
                    done
                fi
                break
            fi
        done
    fi
}

# Function to analyse buffer statistics from logs
analyse_buffer_statistics() {
    local debug_log_file="/tmp/gstreamer_debug.log"
    local log_file="/tmp/gstreamer_production.log"
    
    # Check debug log first (since we're in debug mode by default now)
    for log_path in "$debug_log_file" "$log_file"; do
        if [ -f "$log_path" ]; then
            log_message "INFO: Analysing buffer statistics from $(basename "$log_path")"
            
            # Count buffer-related messages
            local underrun_count=$(grep -c "underrun" "$log_path" 2>/dev/null)
            local overrun_count=$(grep -c "overrun" "$log_path" 2>/dev/null)
            local buffer_full_count=$(grep -c "buffer.*full" "$log_path" 2>/dev/null)
            local buffer_empty_count=$(grep -c "buffer.*empty" "$log_path" 2>/dev/null)
            
            # Ensure we have valid numbers
            underrun_count=${underrun_count:-0}
            overrun_count=${overrun_count:-0}
            buffer_full_count=${buffer_full_count:-0}
            buffer_empty_count=${buffer_empty_count:-0}
            
            # Check if we have meaningful data
            local total_events=$((underrun_count + overrun_count + buffer_full_count + buffer_empty_count))
            
            if [ "$total_events" -eq 0 ]; then
                local log_size=$(wc -l < "$log_path" 2>/dev/null || echo 0)
                if [ "$log_size" -gt 0 ]; then
                    log_message "INFO: Log file has $log_size lines but no buffer events detected"
                    log_message "INFO: This suggests good pipeline health (no buffer issues)"
                else
                    log_message "WARNING: Log file is empty or not found"
                fi
            else
                log_message "INFO: Buffer statistics:"
                log_message "  Underruns: $underrun_count"
                log_message "  Overruns: $overrun_count"
                log_message "  Buffer full events: $buffer_full_count"
                log_message "  Buffer empty events: $buffer_empty_count"
                
                # Look for specific queue information
                local queue_warnings=$(grep -i "queue.*warn\|queue.*error" "$log_path" 2>/dev/null | tail -5)
                if [ -n "$queue_warnings" ]; then
                    log_message "WARNING: Recent queue warnings:"
                    echo "$queue_warnings" | while read -r line; do
                        log_message "  $line"
                    done
                fi
                
                # Check for ALSA buffer issues
                local alsa_issues=$(grep -i "alsa.*xrun\|alsa.*underrun\|alsa.*overrun" "$log_path" 2>/dev/null | tail -3)
                if [ -n "$alsa_issues" ]; then
                    log_message "WARNING: ALSA buffer issues detected:"
                    echo "$alsa_issues" | while read -r line; do
                        log_message "  $line"
                    done
                fi
            fi
            
            # Calculate pipeline uptime if we have the PID
            if [ -n "$PIPELINE_PID" ] && [ -f "/proc/$PIPELINE_PID/stat" ]; then
                local start_time=$(awk '{print $22}' "/proc/$PIPELINE_PID/stat" 2>/dev/null)
                local boot_time=$(awk '/btime/ {print $2}' /proc/stat 2>/dev/null)
                local clock_ticks=$(getconf CLK_TCK 2>/dev/null || echo 100)
                
                if [ -n "$start_time" ] && [ -n "$boot_time" ] && [ -n "$clock_ticks" ]; then
                    local process_start=$((boot_time + start_time / clock_ticks))
                    local current_time=$(date +%s)
                    local uptime=$((current_time - process_start))
                    local hours=$((uptime / 3600))
                    local minutes=$(((uptime % 3600) / 60))
                    local seconds=$((uptime % 60))
                    
                    log_message "INFO: Pipeline uptime: ${hours}h ${minutes}m ${seconds}s"
                fi
            fi
            
            # Show recent performance metrics
            local recent_log_size=$(wc -l < "$log_path" 2>/dev/null || echo 0)
            log_message "INFO: Log file has $recent_log_size lines"
            
            # Only process the first valid log file
            return 0
        fi
    done
    
    # If no log files found, provide guidance
    log_message "WARNING: No GStreamer log files found"
    log_message "INFO: Expected files: $debug_log_file or $log_file"
    log_message "INFO: Checking what log files exist..."
    
    # List available log files
    local available_logs=$(ls -la /tmp/gstreamer*.log 2>/dev/null)
    if [ -n "$available_logs" ]; then
        log_message "INFO: Available log files:"
        echo "$available_logs" | while read -r line; do
            log_message "  $line"
        done
    else
        log_message "WARNING: No GStreamer log files found in /tmp/"
    fi
}

# Function to check ALSA buffer status
check_alsa_buffer_status() {
    log_message "INFO: Checking ALSA buffer status"
    
    # Check ALSA proc info for buffer status
    for card in /proc/asound/card*; do
        if [ -d "$card" ]; then
            local card_name=$(basename "$card")
            local pcm_status="$card/pcm0p/status"
            
            if [ -f "$pcm_status" ]; then
                local status_content=$(cat "$pcm_status" 2>/dev/null)
                if [ -n "$status_content" ]; then
                    log_message "INFO: ALSA $card_name playback status:"
                    echo "$status_content" | grep -E "(state|hw_ptr|appl_ptr|avail)" | while read -r line; do
                        log_message "  $line"
                    done
                fi
            fi
            
            # Check capture status
            local pcm_capture_status="$card/pcm0c/status"
            if [ -f "$pcm_capture_status" ]; then
                local capture_content=$(cat "$pcm_capture_status" 2>/dev/null)
                if [ -n "$capture_content" ]; then
                    log_message "INFO: ALSA $card_name capture status:"
                    echo "$capture_content" | grep -E "(state|hw_ptr|appl_ptr|avail)" | while read -r line; do
                        log_message "  $line"
                    done
                fi
            fi
        fi
    done
}

# Function to check GStreamer pipeline health
check_gstreamer_health() {
    if [ -n "$PIPELINE_PID" ]; then
        # Check both debug and production logs for errors
        local log_files="/tmp/gstreamer_debug.log /tmp/gstreamer_production.log"
        local found_errors=0
        
        for log_file in $log_files; do
            if [ -f "$log_file" ]; then
                local recent_errors=$(tail -100 "$log_file" 2>/dev/null | grep -i "error\|critical\|warning" | tail -5)
                if [ -n "$recent_errors" ]; then
                    log_message "WARNING: Recent GStreamer messages from $(basename "$log_file"):"
                    echo "$recent_errors" | while read -r line; do
                        log_message "  $line"
                    done
                    found_errors=1
                fi
                break
            fi
        done
        
        if [ $found_errors -eq 0 ]; then
            log_message "INFO: No recent GStreamer errors found"
        fi
        
        # Perform buffer analysis
        analyse_buffer_statistics
        
        # Check current buffer status
        check_buffer_status
        
        # Check ALSA buffer status
        check_alsa_buffer_status
    fi
}

# Function to perform comprehensive health check
perform_health_check() {
    log_message "INFO: Starting health check"
    
    local health_status=0
    
    # Check if pipeline is running
    if ! check_pipeline_running; then
        log_message "ERROR: Pipeline process is not running"
        return 1
    fi
    
    # Test audio functionality
    if ! test_audio_capture; then
        health_status=1
    fi
    
    if ! test_audio_playback; then
        health_status=1
    fi
    
    # Check memory usage
    if ! check_memory_usage; then
        health_status=1
    fi
    
    # Check system resources
    check_system_resources
    
    # Check GStreamer health
    check_gstreamer_health
    
    # Perform maintenance
    maintain_alsa_state
    
    if [ $health_status -eq 0 ]; then
        log_message "INFO: Health check completed successfully"
    else
        log_message "WARNING: Health check detected issues"
    fi
    
    return $health_status
}

# Function to start monitoring
start_monitoring() {
    log_message "INFO: Starting AEC pipeline health monitor"
    log_message "INFO: Monitor interval: ${MONITOR_INTERVAL} seconds"
    log_message "INFO: Memory threshold: ${MEMORY_THRESHOLD}KB"
    
    # Get pipeline PID if provided
    if [ -n "$1" ]; then
        PIPELINE_PID="$1"
        log_message "INFO: Monitoring pipeline with PID: $PIPELINE_PID"
    else
        # Try to find gst-launch process
        PIPELINE_PID=$(pgrep -f "gst-launch.*imx_ai_aecnr" | head -1)
        if [ -n "$PIPELINE_PID" ]; then
            log_message "INFO: Found pipeline PID: $PIPELINE_PID"
        else
            log_message "WARNING: Could not find pipeline PID"
        fi
    fi
    
    # Main monitoring loop
    while true; do
        if ! perform_health_check; then
            log_message "WARNING: Health check failed - system may need attention"
        fi
        
        sleep "$MONITOR_INTERVAL"
    done
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -p PID          Monitor specific pipeline PID"
    echo "  -i INTERVAL     Set monitoring interval in seconds (default: 60)"
    echo "  -m MEMORY_MB    Set memory threshold in MB (default: 100)"
    echo "  -l LOGFILE      Set log file path (default: /tmp/aec_monitor.log)"
    echo "  -t              Run single health check and exit"
    echo "  -s              Show buffer statistics from logs"
    echo "  -h              Show this help message"
}

# Parse command line arguments
while getopts "p:i:m:l:tsh" opt; do
    case $opt in
        p)
            PIPELINE_PID="$OPTARG"
            ;;
        i)
            MONITOR_INTERVAL="$OPTARG"
            ;;
        m)
            # Use awk for arithmetic instead of bc
            MEMORY_THRESHOLD=$(echo "$OPTARG" | awk '{print $1 * 1024}')
            ;;
        l)
            LOG_FILE="$OPTARG"
            ;;
        t)
            perform_health_check
            exit $?
            ;;
        s)
            analyse_buffer_statistics
            exit $?
            ;;
        h)
            show_usage
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_usage
            exit 1
            ;;
    esac
done

# Start monitoring
start_monitoring "$PIPELINE_PID"