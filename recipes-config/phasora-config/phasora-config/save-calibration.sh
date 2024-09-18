#!/bin/bash

echo 'SUBSYSTEM=="input", KERNEL=="event[0-9]*",

ENV{ID_INPUT_TOUCHSCREEN}=="1",

ENV{LIBINPUT_CALIBRATION_MATRIX}="'$2 $3 $4 $5 $6 $7'"' >> /etc/udev/rules.d/touchscreen.rules
