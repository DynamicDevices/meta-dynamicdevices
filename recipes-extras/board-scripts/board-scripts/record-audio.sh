# MIT License
# 
# Copyright (c) 2025 Dynamic Devices
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Show help information
show_help() {
    cat << 'EOF'
Continuous Audio Recorder
Copyright (c) 2025 Dynamic Devices - MIT License

USAGE:
    ./record_audio.sh [OPTIONS]

DESCRIPTION:
    Continuously records and analyzes audio clips with configurable duration and intervals.
    By default, audio is analyzed for volume/silence detection and then discarded.
    Use --save-files to keep the recorded audio files.

OPTIONS:
    -h, --help              Show this help message and exit
    -v, --version           Show version information
    -d, --duration SECONDS  Set recording duration in seconds (default: 5)
    -i, --interval SECONDS  Set interval between recordings in seconds (default: 60)
    -l, --log FILE          Log output to file as well as console (optional)
    -a, --audio-device DEV  Audio device to record from (default: default)
    -s, --save-files        Save audio files (default: analyze only, don't save)
        --list-devices      List available audio devices and exit

AUDIO DEVICES:
    Use --list-devices to see available audio input devices.
    Common device formats:
    - default (system default)
    - hw:0,0 (hardware device 0, subdevice 0)
    - plughw:1,0 (plugged hardware device 1, subdevice 0)
    - pulse (PulseAudio default)

EXAMPLES:
    # Basic usage (analyze audio, don't save files)
    ./record_audio.sh
    
    # Save audio files as well as analyzing them
    ./record_audio.sh --save-files
    
    # List available audio devices
    ./record_audio.sh --list-devices
    
    # Record from specific hardware device and save files
    ./record_audio.sh --audio-device hw:1,0 --save-files
    
    # Monitor audio every 10 seconds, save files and log results
    ./record_audio.sh -d 5 -i 10 -s --log monitor.log
    
    # Quick monitoring: 2-second clips every 10 seconds (analysis only)
    ./record_audio.sh -d 2 -i 10
    
    # Long monitoring: 30-second clips every 5 minutes with file saving
    ./record_audio.sh -d 30 -i 300 --save-files
    
    # Log to file as well as console (analysis only)
    ./record_audio.sh --log recording.log
    
    # Full monitoring setup with logging, specific device, and file saving
    ./record_audio.sh -d 5 -i 30 --log /var/log/audio_monitor.log -a hw:1,0 -s
    
    # Show this help
    ./record_audio.sh --help

STOPPING:
    Press any key during recording or during the countdown to stop.
    The script will clean up properly and show total files recorded.

TROUBLESHOOTING:
    - If no audio device found: Use --list-devices to see available devices
    - If files are silent: Check microphone levels with 'alsamixer'
    - For USB microphones: Usually hw:1,0 or hw:2,0
    - For built-in microphones: Usually hw:0,0 or default
    - Volume analysis shows "LIKELY SILENCE": Check audio input levels
    - Device busy error: Another app might be using the microphone

EOF
}

# Show version information
show_version() {
    echo "Continuous Audio Recorder v1.0"
    echo "Copyright (c) 2025 Dynamic Devices"
    echo "MIT License - https://opensource.org/licenses/MIT"
}

# List available audio devices
list_audio_devices() {
    echo "Available Audio Input Devices:"
    echo "=============================="
    
    if command -v arecord >/dev/null 2>&1; then
        echo
        echo "Hardware devices (use with --audio-device):"
        arecord -l 2>/dev/null | grep "^card" | while read line; do
            card=$(echo "$line" | sed 's/card \([0-9]*\).*/\1/')
            device=$(echo "$line" | sed 's/.*device \([0-9]*\).*/\1/')
            name=$(echo "$line" | sed 's/.*\]: \(.*\) \[.*/\1/')
            echo "  hw:${card},${device} - ${name}"
        done
        
        echo
        echo "PCM devices (alternative format):"
        arecord -L 2>/dev/null | grep -E "^(default|pulse|hw:|plughw:)" | head -10 | while read device; do
            echo "  $device"
        done
        
        echo
        echo "Recommended options:"
        echo "  default    - System default input device"
        echo "  pulse      - PulseAudio default (if available)"
        echo "  hw:0,0     - First hardware device (built-in)"
        echo "  hw:1,0     - Second hardware device (USB mic)"
        echo
        echo "Test a device with: arecord -D DEVICE -d 2 test.wav"
    else
        echo "Error: arecord not found. Install alsa-utils package."
        exit 1
    fi
}

# Default values
DURATION=5
INTERVAL=60
LOG_FILE=""
AUDIO_DEVICE="default"
SAVE_FILES=false

# Function to log message to both console and file (if specified)
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Always print to console
    echo "$message"
    
    # Also log to file if specified
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] $message" >> "$LOG_FILE"
    fi
}

# Function to log without timestamp (for progress indicators)
log_progress() {
    local message="$1"
    shift  # Remove first argument
    local formatted_message=$(printf "$message" "$@")
    
    # Print to console
    printf "%s" "$formatted_message"
    
    # Log to file with timestamp if specified
    if [ -n "$LOG_FILE" ]; then
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local clean_message=$(echo "$formatted_message" | sed 's/\r//g' | tr -d '\n')
        echo "[$timestamp] $clean_message" >> "$LOG_FILE"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        -d|--duration)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                DURATION="$2"
                shift 2
            else
                echo "Error: --duration requires a positive integer value"
                echo "Use --help for usage information"
                exit 1
            fi
            ;;
        -i|--interval)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                INTERVAL="$2"
                shift 2
            else
                echo "Error: --interval requires a positive integer value"
                echo "Use --help for usage information"
                exit 1
            fi
            ;;
        --list-devices)
            list_audio_devices
            exit 0
            ;;
        -a|--audio-device)
            if [[ -n "$2" ]]; then
                AUDIO_DEVICE="$2"
                shift 2
            else
                echo "Error: --audio-device requires a device name"
                echo "Use --list-devices to see available devices"
                exit 1
            fi
            ;;
        -s|--save-files)
            SAVE_FILES=true
            shift
            ;;
        -l|--log)
            if [[ -n "$2" ]]; then
                LOG_FILE="$2"
                shift 2
            else
                echo "Error: --log requires a filename"
                echo "Use --help for usage information"
                exit 1
            fi
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            echo "Unexpected argument: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate parameters
if [ "$DURATION" -lt 1 ]; then
    echo "Error: Duration must be at least 1 second"
    exit 1
fi

if [ "$INTERVAL" -lt 0 ]; then
    echo "Error: Interval must be 0 or greater"
    exit 1
fi

# Test audio device before starting
log_message "Testing audio device: $AUDIO_DEVICE"
if ! arecord -D "$AUDIO_DEVICE" -f cd -d 1 /dev/null 2>/dev/null; then
    echo "Error: Cannot access audio device '$AUDIO_DEVICE'"
    echo "Use --list-devices to see available devices"
    echo "Common devices: default, hw:0,0, hw:1,0, pulse"
    exit 1
fi
log_message "✓ Audio device test successful"

# Function to cleanup background processes on exit
cleanup() {
    log_message "Stopping recording..."
    # Kill any remaining arecord processes
    pkill -f "arecord.*audio_"
    exit 0
}

# Set up trap to catch Ctrl+C and cleanup
trap cleanup SIGINT SIGTERM

# Store the original working directory for log file
ORIGINAL_DIR="$(pwd)"

# Initialize log file if specified (before changing directories)
if [ -n "$LOG_FILE" ]; then
    # If relative path, make it relative to original directory
    if [[ "$LOG_FILE" != /* ]]; then
        LOG_FILE="$ORIGINAL_DIR/$LOG_FILE"
    fi
    
    # Create log directory if it doesn't exist
    log_dir=$(dirname "$LOG_FILE")
    if [ "$log_dir" != "." ] && [ "$log_dir" != "$LOG_FILE" ]; then
        mkdir -p "$log_dir" 2>/dev/null || {
            echo "Error: Cannot create log directory: $log_dir"
            exit 1
        }
    fi
    
    # Test if we can write to the log file
    if ! touch "$LOG_FILE" 2>/dev/null; then
        echo "Error: Cannot write to log file: $LOG_FILE"
        exit 1
    fi
fi

# Create directory for audio files only if saving files
if [ "$SAVE_FILES" = true ]; then
    mkdir -p audio_recordings
    cd audio_recordings
    files_location="$(pwd)"
else
    # Use /tmp for temporary analysis files
    cd /tmp
    files_location="/tmp (temporary analysis files)"
fi

# Add session header to log file (after we know the files location)
if [ -n "$LOG_FILE" ]; then
    echo "" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting new recording session" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Duration: ${DURATION}s, Interval: ${INTERVAL}s, Device: $AUDIO_DEVICE" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Save files: $SAVE_FILES, Location: $files_location" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log file: $LOG_FILE" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
fi

log_message "Starting continuous audio monitoring..."
log_message "Each sample will be ${DURATION} seconds long with ${INTERVAL} seconds between recordings"
log_message "Recording from audio device: $AUDIO_DEVICE"
if [ "$SAVE_FILES" = true ]; then
    log_message "Files will be saved as: audio_YYYY-MM-DD_HH-MM-SS.wav"
    log_message "Files location: $files_location"
else
    log_message "Audio analysis only - files will not be saved (use --save-files to keep them)"
fi
log_message "Volume analysis will check for silence/audio detection"
if [ -n "$LOG_FILE" ]; then
    log_message "Logging to: $LOG_FILE"
fi
log_message "Press any key to stop recording"
log_message ""

# Check if volume analysis tools are available
log_message "Checking available analysis tools..."
if command -v sox >/dev/null 2>&1; then
    log_message "✓ Using 'sox' for volume analysis (best option)"
elif command -v ffmpeg >/dev/null 2>&1; then
    log_message "✓ Using 'ffmpeg' for volume analysis"  
elif command -v mediainfo >/dev/null 2>&1; then
    log_message "✓ Using 'mediainfo' for basic audio analysis"
elif command -v file >/dev/null 2>&1; then
    log_message "✓ Using 'file' command for basic validation"
elif command -v hexdump >/dev/null 2>&1; then
    log_message "✓ Using 'hexdump' for data analysis"
else
    log_message "✓ Using file size analysis (basic check)"
fi
log_message ""

# Counter for file numbering (optional backup if timestamp fails)
counter=1
audio_count=0
silence_count=0

# Record session start time for elapsed time calculation
SESSION_START_TIME=$(date +%s)

# Function to calculate and format elapsed time
format_elapsed_time() {
    local current_time=$(date +%s)
    local elapsed_seconds=$((current_time - SESSION_START_TIME))
    local hours=$((elapsed_seconds / 3600))
    local minutes=$(((elapsed_seconds % 3600) / 60))
    local seconds=$((elapsed_seconds % 60))
    
    if [ $hours -gt 0 ]; then
        printf "%02d:%02d:%02d" $hours $minutes $seconds
    else
        printf "%02d:%02d" $minutes $seconds
    fi
}

# Function to log message with elapsed time to console, regular timestamp to file
log_message_with_elapsed() {
    local message="$1"
    local elapsed_time=$(format_elapsed_time)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Print to console with elapsed time
    echo "[$elapsed_time] $message"
    
    # Log to file with regular timestamp if specified
    if [ -n "$LOG_FILE" ]; then
        echo "[$timestamp] $message" >> "$LOG_FILE"
    fi
}
check_keypress() {
    read -t 0.1 -n 1 key 2>/dev/null
    if [ $? = 0 ]; then
        return 0  # Key was pressed
    else
        return 1  # No key pressed
    fi
}

# Main recording loop
while true; do
    # Generate timestamp for filename
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    filename="audio_${timestamp}.wav"
    
    log_message_with_elapsed "Recording: $filename"
    
    # Record audio for specified duration
    # -D specifies the audio device
    # -f cd sets CD quality (16-bit, 44.1kHz, stereo)
    # -d $DURATION sets duration to user-specified seconds
    arecord -D "$AUDIO_DEVICE" -f cd -d "$DURATION" "$filename" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        if [ "$SAVE_FILES" = true ]; then
            log_message_with_elapsed "✓ Saved: $filename"
        else
            log_message_with_elapsed "✓ Recorded and analyzing: $filename"
        fi
        
        # Analyze volume using multiple tools in order of preference
        if command -v sox >/dev/null 2>&1; then
            # Method 1: sox (most accurate)
            volume_stats=$(sox "$filename" -n stat 2>&1)
            rms_amplitude=$(echo "$volume_stats" | grep "RMS.*amplitude" | awk '{print $3}')
            
            if [ ! -z "$rms_amplitude" ]; then
                rms_percent=$(echo "$rms_amplitude * 100" | bc -l 2>/dev/null || echo "scale=2; $rms_amplitude * 100" | bc)
                rms_percent=$(printf "%.2f" "$rms_percent")
                
                silence_threshold=0.01
                if (( $(echo "$rms_amplitude < $silence_threshold" | bc -l) )); then
                    log_message_with_elapsed "  📊 Volume: ${rms_percent}% RMS (⚠️  LIKELY SILENCE)"
                    ((silence_count++))
                else
                    log_message_with_elapsed "  📊 Volume: ${rms_percent}% RMS (✓ Audio detected)"
                    ((audio_count++))
                fi
            else
                log_message_with_elapsed "  📊 Volume analysis failed"
            fi
            
        elif command -v ffmpeg >/dev/null 2>&1; then
            # Method 2: ffmpeg
            volume_info=$(ffmpeg -i "$filename" -af "volumedetect" -f null - 2>&1 | grep "mean_volume")
            mean_volume=$(echo "$volume_info" | grep "mean_volume" | awk '{print $5}')
            
            if [ ! -z "$mean_volume" ]; then
                if (( $(echo "$mean_volume < -60" | bc -l) )); then
                    log_message_with_elapsed "  📊 Volume: ${mean_volume}dB mean (⚠️  LIKELY SILENCE)"
                    ((silence_count++))
                else
                    log_message_with_elapsed "  📊 Volume: ${mean_volume}dB mean (✓ Audio detected)"
                    ((audio_count++))
                fi
            else
                log_message_with_elapsed "  📊 Volume analysis failed"
            fi
            
        elif command -v mediainfo >/dev/null 2>&1; then
            # Method 3: mediainfo (basic info)
            duration=$(mediainfo --Inform="Audio;%Duration%" "$filename" 2>/dev/null)
            bitrate=$(mediainfo --Inform="Audio;%BitRate%" "$filename" 2>/dev/null)
            
            if [ ! -z "$duration" ] && [ "$duration" -gt 0 ]; then
                log_message_with_elapsed "  📊 Duration: ${duration}ms, Bitrate: ${bitrate}bps (✓ File has audio data)"
                ((audio_count++))
            else
                log_message_with_elapsed "  📊 No audio data detected (⚠️  LIKELY SILENCE)"
                ((silence_count++))
            fi
            
        elif command -v file >/dev/null 2>&1; then
            # Method 4: Basic file analysis with simple audio data check
            file_info=$(file "$filename")
            if echo "$file_info" | grep -q "WAVE\|Audio"; then
                # Read a sample of audio data to check for non-zero values
                # Skip WAV header (typically 44 bytes) and check audio data
                sample_data=$(dd if="$filename" bs=1 skip=44 count=1000 2>/dev/null | hexdump -v -e '/1 "%02x"' | grep -v "^00*$" | head -5)
                
                if [ -n "$sample_data" ]; then
                    log_message_with_elapsed "  📊 Audio data detected (✓ Non-zero samples found)"
                    ((audio_count++))
                else
                    log_message_with_elapsed "  📊 All samples appear to be zero (⚠️  LIKELY SILENCE)"
                    ((silence_count++))
                fi
            else
                log_message_with_elapsed "  📊 Invalid audio file format (⚠️  ERROR)"
            fi
            
        elif command -v hexdump >/dev/null 2>&1; then
            # Method 5: Hex analysis (skip WAV header, check audio data)
            # Skip first 44 bytes (WAV header) and check actual audio data
            audio_data=$(dd if="$filename" bs=1 skip=44 count=2000 2>/dev/null | hexdump -v -e '/1 "%02x"')
            non_zero_bytes=$(echo "$audio_data" | grep -v "^00*$" | wc -l)
            
            if [ "$non_zero_bytes" -gt 10 ]; then
                log_message_with_elapsed "  📊 Non-zero audio data detected (✓ Audio samples present)"
                ((audio_count++))
            else
                log_message_with_elapsed "  📊 Mostly zero audio data (⚠️  LIKELY SILENCE)"
                ((silence_count++))
            fi
            
        else
            # Method 6: Advanced file analysis using od (octal dump)
            if command -v od >/dev/null 2>&1; then
                # Skip WAV header and check for non-zero audio samples
                non_zero_samples=$(dd if="$filename" bs=1 skip=44 count=1000 2>/dev/null | od -t u1 | awk '{for(i=2;i<=NF;i++) if($i>5) print $i}' | wc -l)
                
                if [ "$non_zero_samples" -gt 20 ]; then
                    log_message_with_elapsed "  📊 Audio samples detected (✓ Non-zero data found)"
                    ((audio_count++))
                else
                    log_message_with_elapsed "  📊 Very quiet audio data (⚠️  LIKELY SILENCE)"
                    ((silence_count++))
                fi
            else
                # Final fallback: just confirm file was created
                file_size=$(stat -f%z "$filename" 2>/dev/null || stat -c%s "$filename" 2>/dev/null)
                log_message_with_elapsed "  📊 File created: ${file_size} bytes (⚠️  Cannot analyse audio content)"
                # Count as unknown/audio since we can't determine silence
                ((audio_count++))
            fi
        fi
        
        # Delete temporary file if not saving files
        if [ "$SAVE_FILES" = false ]; then
            rm -f "$filename"
        fi
        
        # Show running totals with elapsed time
        current_elapsed=$(format_elapsed_time)
        log_message_with_elapsed "  📈 Running totals: Audio=${audio_count}, Silence=${silence_count}, Total time=${current_elapsed}"
    else
        log_message_with_elapsed "✗ Error recording $filename"
    fi
    
    # Check if a key was pressed during or after recording
    if check_keypress; then
        log_message "Key pressed - stopping recording"
        break
    fi
    
    # Increment counter
    ((counter++))
    
    # Configurable delay between recordings
    if [ "$INTERVAL" -gt 0 ]; then
        echo "Waiting ${INTERVAL} seconds before next recording..."
        for (( i=INTERVAL; i>=0; i-- )); do
            printf "\rNext recording in: %2d seconds (press any key to stop)" $i
            
            # Don't sleep after showing 0
            if [ $i -gt 0 ]; then
                sleep 1
            fi
            
            # Check for keypress during countdown
            if check_keypress; then
                log_message "Key pressed - stopping recording"
                cleanup
            fi
        done
        echo "" # New line after countdown
    else
        # No interval - check for immediate keypress
        if check_keypress; then
            log_message "Key pressed - stopping recording"
            break
        fi
    fi
done

log_message "Recording stopped."
if [ "$SAVE_FILES" = true ]; then
    log_message "Files saved in: $files_location"
    log_message "Total files recorded: $((counter-1))"
else
    log_message "Total audio samples analyzed: $((counter-1))"
fi

# Calculate final elapsed time
final_elapsed=$(format_elapsed_time)

log_message "📊 Final Statistics:"
log_message "  ✓ Samples with audio detected: $audio_count"
log_message "  ⚠️  Samples with silence detected: $silence_count"
log_message "  📈 Total samples processed: $((audio_count + silence_count))"
log_message "  ⏱️  Total session time: $final_elapsed"
if [ $((audio_count + silence_count)) -gt 0 ]; then
    audio_percentage=$(echo "scale=1; $audio_count * 100 / ($audio_count + $silence_count)" | bc -l 2>/dev/null || echo "0")
    silence_percentage=$(echo "scale=1; $silence_count * 100 / ($audio_count + $silence_count)" | bc -l 2>/dev/null || echo "0")
    log_message "  📊 Audio detection rate: ${audio_percentage}%"
    log_message "  📊 Silence detection rate: ${silence_percentage}%"
fi

# Add session end to log file
if [ -n "$LOG_FILE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session ended - see final statistics above" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
fi