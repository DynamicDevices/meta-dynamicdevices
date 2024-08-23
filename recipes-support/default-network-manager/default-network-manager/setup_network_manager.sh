#!/bin/sh

# Wait until Network Manager up
sleep 10
# Alex
nmcli device wifi connect VM0184406-2G password 2sqmsfFGqpry ifname wlan0
# Quectel GSM (no autoconnect)
nmcli con add type gsm con-name "quectel" gsm.apn quectel.tn.std connection.autoconnect false
