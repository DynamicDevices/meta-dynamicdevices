#!/bin/sh

# Delayed wireless module loading for imx93-jaguar-eink
# Load wireless modules after boot completion for faster initial boot

echo "Loading wireless modules after boot completion..."

# Load WiFi modules
modprobe mlan 2>/dev/null || echo "mlan module already loaded or not available"
modprobe moal 2>/dev/null || echo "moal module already loaded or not available"

# Load Bluetooth modules  
modprobe bluetooth 2>/dev/null || echo "bluetooth module already loaded or not available"

# Load 802.15.4 modules
modprobe ieee802154 2>/dev/null || echo "ieee802154 module already loaded or not available"
modprobe ieee802154_socket 2>/dev/null || echo "ieee802154_socket module already loaded or not available"
modprobe 6lowpan 2>/dev/null || echo "6lowpan module already loaded or not available"

echo "Wireless modules loading completed"

# Optional: Start wireless services if they were disabled during boot
# systemctl start bluetooth.service
# systemctl start wpa_supplicant.service
