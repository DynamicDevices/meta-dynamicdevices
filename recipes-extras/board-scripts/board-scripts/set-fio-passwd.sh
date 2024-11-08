#!/bin/sh

SERIAL_NUMBER=`cat /sys/devices/soc0/serial_number`
echo -e -n "fio\n${SERIAL_NUMBER}\n${SERIAL_NUMBER}\n" | passwd fio
