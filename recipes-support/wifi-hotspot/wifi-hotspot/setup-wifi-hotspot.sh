#!/bin/sh

# NOTE: MASSIVE SECURITY RISK! THIS SHOULD ONLY BE USED FOR DEVELOPMENT PURPOSES
#
# NOTE: Currently this will only work with WiFi drivers which support uap0 for AP

# Wait until Network Manager up
sleep 10

# Now setup the AP
nmcli con add type wifi ifname uap0 con-name hotspot autoconnect yes ssid jaguar-hotspot
nmcli con modify hotspot 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
nmcli con modify hotspot wifi-sec.key-mgmt wpa-psk
nmcli con modify hotspot wifi-sec.psk "decafbad00"
nmcli con up hotspot





