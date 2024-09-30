#!/bin/sh

echo Powering down modem
echo -e "AT+QPOWD\r" > /dev/ttyUSB3

