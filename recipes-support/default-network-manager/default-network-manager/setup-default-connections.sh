#!/bin/sh
#
# NetworkManager Default Connection Setup Script
#
# This script is called during system initialization to set up default
# WiFi connections. It should be customized for each product/board.
#
# IMPORTANT: For headless embedded systems, connections MUST be configured
# with the following settings to prevent "no secrets" errors and ensure
# reliable auto-reconnection:
#
# 1. psk-flags=0          - Store PSK in connection file (not agent-only)
# 2. autoconnect-retries=-1 - Retry connection indefinitely (never give up)
# 3. auth-retries=-1      - Retry authentication indefinitely
# 4. permissions=""       - Allow system-wide use (not user-specific)
# 5. Save to keyfile      - Force save to ensure secrets persist
#
# Without these settings, NetworkManager may:
# - Clear secrets on 4-way handshake failure
# - Request new secrets from non-existent secret agent
# - Enter "no secrets" state and block auto-reconnection
# - Fail permanently after transient network issues
#
# See NETWORKMANAGER_NO_SECRETS_ANALYSIS.md for detailed explanation.
#

# Example WiFi connection setup (commented out - customize for your product)
#
# CONNECTION_NAME="MyWiFiNetwork"
# SSID="MyWiFiNetwork"
# PSK="your-wifi-password-here"
# INTERFACE="wlan0"
# PRIORITY=10
#
# # Check if connection already exists, if so modify it, otherwise add it
# if nmcli connection show "$CONNECTION_NAME" >/dev/null 2>&1; then
#     # Connection exists, modify it
#     nmcli connection modify "$CONNECTION_NAME" \
#         type wifi \
#         ifname "$INTERFACE" \
#         ssid "$SSID" \
#         802-11-wireless-security.key-mgmt WPA-PSK \
#         802-11-wireless-security.psk "$PSK" \
#         802-11-wireless-security.psk-flags 0 \
#         connection.autoconnect yes \
#         connection.autoconnect-priority $PRIORITY \
#         connection.autoconnect-retries -1 \
#         connection.auth-retries -1 \
#         connection.permissions ""
# else
#     # Connection doesn't exist, add it
#     nmcli con add type wifi \
#         con-name "$CONNECTION_NAME" \
#         ifname "$INTERFACE" \
#         ssid "$SSID" \
#         802-11-wireless-security.key-mgmt WPA-PSK \
#         802-11-wireless-security.psk "$PSK" \
#         802-11-wireless-security.psk-flags 0 \
#         connection.autoconnect yes \
#         connection.autoconnect-priority $PRIORITY \
#         connection.autoconnect-retries -1 \
#         connection.auth-retries -1 \
#         connection.permissions ""
# fi
#
# # Save connection to keyfile (ensures secrets are in file, not agent-only)
# # This prevents "no secrets" errors on headless systems when 4-way handshake fails
# nmcli connection save "$CONNECTION_NAME"
#
# # Activate the connection to establish device binding
# # This ensures autoconnect will work on future boots
# nmcli connection up "$CONNECTION_NAME" || true

# Configuration Parameters Explained:
#
# 802-11-wireless-security.psk-flags 0
#   - 0 = Store PSK in connection file (required for headless systems)
#   - 1 = Agent-only (requires secret agent - will fail on headless systems)
#   - 2 = Not saved (requires secret agent - will fail on headless systems)
#
# connection.autoconnect-retries -1
#   - -1 = Unlimited retries (recommended for embedded systems)
#   - 0 = No retries (will fail permanently)
#   - N = Retry N times then give up (not recommended for production)
#
# connection.auth-retries -1
#   - -1 = Unlimited authentication retries (recommended)
#   - 0 = No retries (will fail permanently)
#   - N = Retry N times then give up (not recommended)
#
# connection.permissions ""
#   - "" = System-wide connection (accessible to all users/system)
#   - "user:username" = User-specific (may cause issues on headless systems)
#
# nmcli connection save
#   - Forces save to keyfile format (/etc/NetworkManager/system-connections/)
#   - Ensures secrets are persisted and available on reboot
#   - Required to prevent NetworkManager from clearing secrets on failure

# Exit successfully (script may be empty for products that don't need default connections)
exit 0
