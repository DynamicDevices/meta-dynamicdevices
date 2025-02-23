#!/bin/sh

# Check if running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root by running this command with sudo 'sudo set-fio-passwd.sh' and entering the password"
  exit
fi

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

# Set the password as the fio user
sudo -u fio echo -e -n "fio\n${CIPHERTEXT}\n${CIPHERTEXT}\n" | sudo -u fio passwd
