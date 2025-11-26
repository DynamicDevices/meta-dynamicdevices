#!/bin/sh

# Setup default network connections for testing
# This script will look for a local wifi configuration file

CONFIG_FILE="$(dirname "$0")/wifi-config.local"

# Check if local WiFi config exists (git-ignored file)
if [ -f "${CONFIG_FILE}" ]; then
    echo "Found local WiFi configuration, setting up connection..."
    
    # Source the configuration
    . "${CONFIG_FILE}"
    
    # Set defaults if not specified
    WIFI_CONNECTION_NAME="${WIFI_CONNECTION_NAME:-test-wifi}"
    WIFI_PRIORITY="${WIFI_PRIORITY:-10}"
    WIFI_AUTOCONNECT="${WIFI_AUTOCONNECT:-yes}"
    
    # Check if connection already exists
    if nmcli con show "${WIFI_CONNECTION_NAME}" >/dev/null 2>&1; then
        echo "Connection '${WIFI_CONNECTION_NAME}' already exists, removing first..."
        nmcli con delete "${WIFI_CONNECTION_NAME}"
    fi
    
    # Create the WiFi connection
    echo "Creating WiFi connection '${WIFI_CONNECTION_NAME}' for SSID '${WIFI_SSID}'..."
    nmcli con add type wifi con-name "${WIFI_CONNECTION_NAME}" \
        ssid "${WIFI_SSID}" \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "${WIFI_PASSWORD}" \
        connection.autoconnect "${WIFI_AUTOCONNECT}" \
        connection.autoconnect-priority "${WIFI_PRIORITY}"
    
    if [ $? -eq 0 ]; then
        echo "WiFi connection '${WIFI_CONNECTION_NAME}' created successfully"
        echo "Attempting to connect..."
        nmcli con up "${WIFI_CONNECTION_NAME}"
    else
        echo "Failed to create WiFi connection"
    fi
else
    echo "No local WiFi configuration found at ${CONFIG_FILE}"
    echo "Copy wifi-config.local.example to wifi-config.local and configure your test network"
fi

