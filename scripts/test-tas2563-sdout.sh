#!/bin/bash

#
# TAS2563 SDout Test Script
#
# This script tests the TAS2563 Serial Data Output (SDout) capture functionality
# on the imx8mm-jaguar-sentai board.
#
# Copyright (c) 2024 Dynamic Devices Ltd.
# Licensed under the GNU General Public License v3.0
#

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warn "Running as root - this is not required for audio testing"
    fi
}

# Check if TAS2563 audio card is available
check_audio_card() {
    log_info "Checking for TAS2563 audio card..."
    
    if aplay -l | grep -q "tas2563audio"; then
        log_success "TAS2563 audio card found"
        return 0
    else
        log_error "TAS2563 audio card not found"
        log_info "Available audio cards:"
        aplay -l
        return 1
    fi
}

# Check if TAS2563 capture is available
check_capture_device() {
    log_info "Checking for TAS2563 capture device..."
    
    if arecord -l | grep -q "tas2563audio"; then
        log_success "TAS2563 capture device found"
        return 0
    else
        log_error "TAS2563 capture device not found"
        log_info "Available capture devices:"
        arecord -l
        return 1
    fi
}

# Test TAS2563 SDout capture
test_sdout_capture() {
    local duration=${1:-5}
    local output_file="tas2563_sdout_test_$(date +%Y%m%d_%H%M%S).wav"
    
    log_info "Testing TAS2563 SDout capture for ${duration} seconds..."
    log_info "Output file: $output_file"
    
    # Test different ALSA devices
    local devices=("tas2563_sdout" "hw:tas2563audio,0" "tas2563_sdout_vc")
    
    for device in "${devices[@]}"; do
        log_info "Testing capture device: $device"
        
        if timeout "${duration}s" arecord -D "$device" -f S16_LE -r 48000 -c 2 "$output_file" 2>/dev/null; then
            log_success "Capture test successful with device: $device"
            
            # Check if file was created and has content
            if [[ -f "$output_file" && -s "$output_file" ]]; then
                local size=$(du -h "$output_file" | cut -f1)
                log_success "Recorded file: $output_file (size: $size)"
                
                # Play back the recorded audio (optional)
                read -p "Play back recorded audio? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log_info "Playing back recorded audio..."
                    aplay "$output_file" || log_warn "Playback failed"
                fi
                
                return 0
            else
                log_error "Recorded file is empty or missing"
            fi
        else
            log_warn "Capture test failed with device: $device"
        fi
        
        # Clean up empty files
        [[ -f "$output_file" && ! -s "$output_file" ]] && rm -f "$output_file"
    done
    
    return 1
}

# Test simultaneous playback and capture (full-duplex)
test_full_duplex() {
    local duration=${1:-10}
    local test_tone_freq=${2:-1000}
    
    log_info "Testing full-duplex operation (playback + SDout capture)..."
    log_info "Duration: ${duration}s, Test tone: ${test_tone_freq}Hz"
    
    local capture_file="tas2563_duplex_capture_$(date +%Y%m%d_%H%M%S).wav"
    
    # Start capture in background
    log_info "Starting SDout capture..."
    timeout "${duration}s" arecord -D tas2563_sdout -f S16_LE -r 48000 -c 2 "$capture_file" &
    local capture_pid=$!
    
    # Wait a moment for capture to start
    sleep 1
    
    # Generate and play test tone
    log_info "Playing ${test_tone_freq}Hz test tone..."
    timeout "$((duration-2))s" speaker-test -t sine -f "$test_tone_freq" -c 2 -D spk_vc &
    local playback_pid=$!
    
    # Wait for both processes
    wait $capture_pid 2>/dev/null || true
    wait $playback_pid 2>/dev/null || true
    
    # Check results
    if [[ -f "$capture_file" && -s "$capture_file" ]]; then
        local size=$(du -h "$capture_file" | cut -f1)
        log_success "Full-duplex test completed: $capture_file (size: $size)"
        
        # Analyze captured audio (basic check)
        log_info "Analyzing captured audio..."
        if command -v sox &> /dev/null; then
            sox "$capture_file" -n stat 2>&1 | grep -E "(RMS|Maximum) amplitude" || true
        fi
        
        return 0
    else
        log_error "Full-duplex test failed - no capture data"
        return 1
    fi
}

# Show ALSA mixer controls
show_mixer_controls() {
    log_info "TAS2563 ALSA mixer controls:"
    echo
    
    if amixer -c tas2563audio controls 2>/dev/null; then
        echo
        log_info "Current mixer settings:"
        amixer -c tas2563audio 2>/dev/null || log_warn "Could not read mixer settings"
    else
        log_warn "Could not access TAS2563 mixer controls"
    fi
}

# Main function
main() {
    local duration=5
    local test_tone=1000
    local full_duplex=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--duration)
                duration="$2"
                shift 2
                ;;
            -f|--frequency)
                test_tone="$2"
                shift 2
                ;;
            --full-duplex)
                full_duplex=true
                shift
                ;;
            -h|--help)
                cat << EOF
Usage: $0 [OPTIONS]

Test TAS2563 SDout capture functionality.

Options:
  -d, --duration SECONDS    Test duration in seconds (default: 5)
  -f, --frequency HZ        Test tone frequency for full-duplex test (default: 1000)
  --full-duplex            Run full-duplex test (playback + capture)
  -h, --help               Show this help message

Examples:
  $0                       # Basic SDout capture test (5 seconds)
  $0 -d 10                 # 10-second capture test
  $0 --full-duplex -d 15   # 15-second full-duplex test
  $0 -f 440 --full-duplex # Full-duplex test with 440Hz tone

EOF
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    log_info "TAS2563 SDout Test Script"
    echo
    
    # Run checks
    check_root
    
    if ! check_audio_card; then
        exit 1
    fi
    
    if ! check_capture_device; then
        exit 1
    fi
    
    # Show mixer controls
    show_mixer_controls
    echo
    
    # Run tests
    if [[ "$full_duplex" == true ]]; then
        if test_full_duplex "$duration" "$test_tone"; then
            log_success "Full-duplex test completed successfully"
        else
            log_error "Full-duplex test failed"
            exit 1
        fi
    else
        if test_sdout_capture "$duration"; then
            log_success "SDout capture test completed successfully"
        else
            log_error "SDout capture test failed"
            exit 1
        fi
    fi
    
    echo
    log_info "Test completed. Check recorded files for audio content."
    log_info "Use 'aplay <filename>' to play back recorded audio."
}

# Run main function with all arguments
main "$@"
