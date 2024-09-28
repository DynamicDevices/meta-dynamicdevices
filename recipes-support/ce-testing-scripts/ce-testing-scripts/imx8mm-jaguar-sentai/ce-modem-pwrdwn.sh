#!/bin/sh

echo Powering down modem
echo "AT+QPOWD" > /dev/ttyUSB3

