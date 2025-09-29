#!/bin/bash
#
# Target Board Debug Setup Script
# Automates setup of Dynamic Devices target boards for debugging and development
#
# Usage: ./setup-target-debug.sh <target-ip> [username] [password]
# Example: ./setup-target-debug.sh 192.168.0.203 fio fio
#
# Features:
# - Configures passwordless SSH access
# - Sets up passwordless sudo
# - Checks USB audio gadget support
# - Validates target board connectivity and capabilities
#
# Author: Alex J Lennon <ajlennon@dynamicdevices.co.uk>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

usage() {
    cat << USAGE
Usage: $0 <target-ip> [username] [password]

Setup target board for debugging and development access.

Arguments:
  target-ip    IP address of target board (required)
  username     SSH username (default: fio)
  password     SSH password (default: fio)

Examples:
  $0 192.168.0.203
  $0 192.168.0.203 fio mypassword
  $0 10.0.0.100 root admin

Features:
  - Removes old SSH host keys
  - Configures passwordless SSH access
  - Sets up passwordless sudo
  - Checks USB audio gadget support
  - Validates board capabilities

Prerequisites:
  - sshpass installed (sudo apt install sshpass)
  - SSH public key available (~/.ssh/id_*.pub)
  - Target board accessible on network

USAGE
}

# Parse arguments
if [[ $# -lt 1 ]]; then
    echo "Error: Target IP address required"
    usage
    exit 1
fi

TARGET_IP="$1"
USERNAME="${2:-fio}"
PASSWORD="${3:-fio}"

log_info "Target Board Debug Setup"
log_info "Target IP: $TARGET_IP"
log_info "Username: $USERNAME"
echo

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v sshpass &> /dev/null; then
    log_error "sshpass not found. Install with: sudo apt install sshpass"
    exit 1
fi

# Find SSH public key
SSH_PUBKEY=""
for key_type in ed25519 rsa ecdsa; do
    if [[ -f "$HOME/.ssh/id_${key_type}.pub" ]]; then
        SSH_PUBKEY="$HOME/.ssh/id_${key_type}.pub"
        break
    fi
done

if [[ -z "$SSH_PUBKEY" ]]; then
    log_error "No SSH public key found. Generate one with: ssh-keygen -t ed25519"
    exit 1
fi

log_success "Prerequisites OK"
log_info "Using SSH public key: $SSH_PUBKEY"
echo

# Step 1: Remove old host key and test connectivity
log_info "Step 1: Testing connectivity and removing old host keys..."

# Remove old host key if it exists
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$TARGET_IP" 2>/dev/null || true

# Test basic connectivity
if sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$USERNAME@$TARGET_IP" "echo 'Connection test successful'" &>/dev/null; then
    log_success "Successfully connected to $TARGET_IP"
else
    log_error "Failed to connect to $TARGET_IP. Check network connectivity and credentials."
    exit 1
fi

# Step 2: Configure passwordless sudo
log_info "Step 2: Configuring passwordless sudo for $USERNAME..."

if sshpass -p "$PASSWORD" ssh "$USERNAME@$TARGET_IP" "echo '$PASSWORD' | sudo -S sh -c 'echo \"$USERNAME ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'" 2>/dev/null; then
    log_success "Passwordless sudo configured"
else
    log_warn "Failed to configure passwordless sudo (may already be configured)"
fi

# Step 3: Copy SSH public key
log_info "Step 3: Setting up passwordless SSH access..."

if sshpass -p "$PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no "$USERNAME@$TARGET_IP" &>/dev/null; then
    log_success "SSH public key copied successfully"
else
    log_warn "Failed to copy SSH key (may already be configured)"
fi

# Step 4: Test passwordless access
log_info "Step 4: Testing passwordless access..."

if ssh -o ConnectTimeout=10 "$USERNAME@$TARGET_IP" "sudo whoami" &>/dev/null; then
    log_success "Passwordless SSH and sudo working correctly"
else
    log_error "Passwordless access test failed"
    exit 1
fi

# Step 5: Check target board capabilities
log_info "Step 5: Checking target board capabilities..."

BOARD_INFO=$(ssh "$USERNAME@$TARGET_IP" "
echo '=== Board Information ==='
echo 'Hostname: '$(hostname)
echo 'Kernel: '$(uname -r)
echo 'Architecture: '$(uname -m)
echo 'Uptime: '$(uptime | cut -d',' -f1)

echo -e '\n=== USB Audio Gadget Support ==='
if [[ -f /usr/bin/setup-usb-audio-gadget ]]; then
    echo 'USB Audio Script: INSTALLED'
    echo 'Script version: '$(stat -c %y /usr/bin/setup-usb-audio-gadget | cut -d' ' -f1)
else
    echo 'USB Audio Script: NOT INSTALLED'
fi

echo -e '\n=== USB Gadget Kernel Support ==='
if lsmod | grep -q libcomposite; then
    echo 'libcomposite module: LOADED'
else
    echo 'libcomposite module: NOT LOADED'
fi

if mount | grep -q configfs; then
    echo 'ConfigFS: MOUNTED'
else
    echo 'ConfigFS: NOT MOUNTED'
fi

echo -e '\n=== USB Controllers ==='
if [[ -d /sys/class/udc && -n \$(ls /sys/class/udc/ 2>/dev/null) ]]; then
    echo 'USB Device Controllers: '$(ls /sys/class/udc/)
else
    echo 'USB Device Controllers: NONE (USB port not in device mode)'
fi

echo -e '\n=== USB OTG Role Switching ==='
role_switches=\$(find /sys -name 'role' 2>/dev/null | wc -l)
if [[ \$role_switches -gt 0 ]]; then
    echo 'USB OTG role switches: '\$role_switches' found'
    for role_path in \$(find /sys -name 'role' 2>/dev/null | head -3); do
        current_role=\$(cat \$role_path 2>/dev/null || echo 'unknown')
        echo '  '\$role_path': '\$current_role
    done
else
    echo 'USB OTG role switches: NONE'
fi

echo -e '\n=== Audio Devices ==='
if command -v aplay &>/dev/null; then
    playback_devices=\$(aplay -l 2>/dev/null | grep -c '^card' || echo '0')
    capture_devices=\$(arecord -l 2>/dev/null | grep -c '^card' || echo '0')
    echo 'ALSA playback devices: '\$playback_devices
    echo 'ALSA capture devices: '\$capture_devices
else
    echo 'ALSA tools: NOT AVAILABLE'
fi
")

echo "$BOARD_INFO"

# Step 6: USB Audio Gadget Status
log_info "Step 6: Checking USB Audio Gadget status..."

if ssh "$USERNAME@$TARGET_IP" "command -v setup-usb-audio-gadget" &>/dev/null; then
    USB_STATUS=$(ssh "$USERNAME@$TARGET_IP" "setup-usb-audio-gadget status 2>/dev/null" || echo "Status check failed")
    echo "$USB_STATUS"
else
    log_warn "USB Audio Gadget script not installed on target"
fi

echo
log_success "Target board debug setup completed!"
echo
log_info "Summary:"
log_info "  Target: $USERNAME@$TARGET_IP"
log_info "  SSH: Passwordless access configured"
log_info "  Sudo: Passwordless sudo configured"
log_info "  USB Audio: $(if ssh "$USERNAME@$TARGET_IP" "command -v setup-usb-audio-gadget" &>/dev/null; then echo "Available"; else echo "Not installed"; fi)"
echo
log_info "Next steps:"
log_info "  1. Connect to target: ssh $USERNAME@$TARGET_IP"
log_info "  2. Test USB audio: setup-usb-audio-gadget status"
log_info "  3. Switch USB to device mode if needed for USB audio gadget testing"
echo
log_info "For USB gadget mode, you may need to physically switch USB connector"
log_info "or use role switching: echo 'device' | sudo tee /sys/devices/.../role"
