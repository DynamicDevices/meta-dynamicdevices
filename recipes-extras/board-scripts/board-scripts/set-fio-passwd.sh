#!/bin/sh

SALT=DynamicDevices

if [ -f /etc/salt ]; then
  . /etc/salt
fi

echo Salt: ${SALT}

# Get the SOC serial number
SERIAL_SOURCE=`cat /sys/devices/soc0/serial_number`
SERIAL=$(echo ${SERIAL_SOURCE} | sed -e 's/^0*//' | tr '[:upper:]' '[:lower:]' | tr -d '\0')

# Get the WLAN MAC ID
#WLAN_MAC=`ifconfig wlan0 | grep ether | cut -c 15-31`

echo Serial Number: ${SERIAL}

# Create the hash
CIPHERTEXT=`echo "${SALT}|${SERIAL}|" | sha256sum | cut -f 1 -d ' '`

echo Password: ${CIPHERTEXT}

# Set the password
echo -e -n "fio\n${CIPHERTEXT}\n${CIPHERTEXT}\n" | passwd
