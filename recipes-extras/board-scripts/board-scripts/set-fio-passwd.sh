#!/bin/sh

SERIAL_SOURCE=`cat /sys/devices/soc0/serial_number`
SERIAL=$(sed -e 's/^0*//' ${SERIAL_SOURCE} | tr '[:upper:]' '[:lower:]' | tr -d '\0')
echo -e -n "fio\n${SERIAL}\n${SERIAL}\n" | passwd fio
