# Local WiFi Testing Configuration

This document explains how to add a default WiFi connection to your image for testing purposes without committing sensitive credentials to the repository.

## Quick Setup

### 1. Create Local WiFi Configuration

Copy the example configuration and customize it with your network details:

```bash
cd recipes-support/default-network-manager/default-network-manager/
cp wifi-config.local.example wifi-config.local
```

### 2. Edit Your WiFi Credentials

Edit `wifi-config.local` (this file is git-ignored):

```bash
# Example WiFi configuration for local testing
WIFI_SSID="YourTestNetwork"
WIFI_PASSWORD="YourPassword"
WIFI_CONNECTION_NAME="test-wifi"

# Optional: Priority (higher number = higher priority)
WIFI_PRIORITY="10"

# Optional: Auto-connect on boot
WIFI_AUTOCONNECT="yes"
```

### 3. Build and Flash

Build your image as usual. The WiFi connection will be automatically configured on first boot.

## How It Works

1. **Package Installation**: The `default-network-manager` package is included in the eink image
2. **First Boot Service**: A systemd service runs once on first boot to set up network connections
3. **Local Configuration**: The service looks for `wifi-config.local` and creates an nmcli connection
4. **Auto-Disable**: The service disables itself after running once

## Runtime Behavior

On first boot, you'll see log messages like:
```
Found local WiFi configuration, setting up connection...
Creating WiFi connection 'test-wifi' for SSID 'YourTestNetwork'...
WiFi connection 'test-wifi' created successfully
Attempting to connect...
```

## Manual Testing

You can also test the script manually after boot:
```bash
# SSH into your device and run:
/usr/bin/setup-default-connections.sh
```

## Troubleshooting

### Check Service Status
```bash
systemctl status setup-default-connections.service
journalctl -u setup-default-connections.service
```

### Manual Network Management
```bash
# List connections
nmcli con show

# Check WiFi status
nmcli dev wifi

# Connect manually
nmcli con up test-wifi
```

### Remove Test Connection
```bash
nmcli con delete test-wifi
```

## Security Notes

- The `wifi-config.local` file is added to `.gitignore` and will not be committed
- WiFi passwords are stored in NetworkManager's connection files on the target device
- This is intended for development/testing only, not production deployment

## Alternative: Environment Variables

You can also set WiFi credentials via environment variables in your build system:

```bash
export TEST_WIFI_SSID="YourNetwork"
export TEST_WIFI_PASSWORD="YourPassword"
# Then modify the script to use these if wifi-config.local doesn't exist
```

## Production Deployment

For production, consider:
- Using NetworkManager's keyfile format with proper permissions
- Implementing a proper onboarding/provisioning system
- Using WPA Enterprise with certificates instead of PSK
