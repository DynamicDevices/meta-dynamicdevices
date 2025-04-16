#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024 NXP

CONFIGFS=/sys/kernel/config/usb_gadget
if ! [ -e "$CONFIGFS" ]; then
	echo "  $CONFIGFS does not exist, skipping configfs usb gadget"
	return
fi

GADGET=$CONFIGFS/g1
CONFIG=$GADGET/configs/c.1
FUNCTIONS=$GADGET/functions

VID="0x1fc9"
PID="0x0330"
SERIALNUMBER="0123456789"
MANUFACTURER="NXP Semiconductors"
PRODUCT="i.MX"
SAMPLE_RATE=16000
SAMPLE_SIZE=4 # 32-bit

export MIC_DEVICE="hw:micfilaudio,0"
export USB_REMOTE_DEVICE="hw:UAC2Gadget,0"
export USB_ACTIVE_DEVICE="hw:UAC2Gadget,0"

function add_uac2_function() {
  mkdir $FUNCTIONS/uac2.$1 || echo "  Couldn't create $FUNCTIONS/uac2.$1"

  echo "$PRODUCT $1" >$FUNCTIONS/uac2.$1/function_name
  echo $SAMPLE_RATE >$FUNCTIONS/uac2.$1/c_srate
  echo $SAMPLE_RATE >$FUNCTIONS/uac2.$1/p_srate
  echo $SAMPLE_SIZE >$FUNCTIONS/uac2.$1/c_ssize
  echo $SAMPLE_SIZE >$FUNCTIONS/uac2.$1/p_ssize
  echo $2 >$FUNCTIONS/uac2.$1/c_chmask
  echo $3 >$FUNCTIONS/uac2.$1/p_chmask

  echo 0x1 >$FUNCTIONS/uac2.$1/c_mute_present
  echo 0x1 >$FUNCTIONS/uac2.$1/c_volume_present
  echo 0x1 >$FUNCTIONS/uac2.$1/p_mute_present
  echo 0x1 >$FUNCTIONS/uac2.$1/p_volume_present

  ln -s $FUNCTIONS/uac2.$1 $CONFIG || echo "  Couldn't symlink uac2.$1"
}

get_speaker_device() {
    # Use aplay to list the sound cards and filter the desired line
    local aplay_output
    aplay_output=$(aplay -l | grep -E "card [0-9]+: wm.*audio" | tail -1)

    # Extract the card name and device number using awk
    local card_name
    local device_number
    card_name=$(echo "$aplay_output" | awk '{print $3}' | awk -F: '{print $1}')
    device_number=$(echo "$aplay_output" | awk -F 'device ' '{print $2}' | awk -F ':' '{print $1}')

    # Construct the hw string
    local speaker_device
    speaker_device="hw:${card_name},${device_number}"

    # Return the result
    echo "$speaker_device"
}

export SPEAKER_DEVICE=$(get_speaker_device)

function create_config() {
  # Create an usb gadet configuration
  mkdir $GADGET || echo "  Couldn't create $GADGET"
  echo $VID >$GADGET/idVendor
  echo $PID >$GADGET/idProduct

  mkdir $GADGET/strings/0x409 || echo "  Couldn't create $GADGET/g1/strings/0x409"
  echo $SERIALNUMBER >$GADGET/strings/0x409/serialnumber
  echo $MANUFACTURER >$GADGET/strings/0x409/manufacturer
  echo $PRODUCT >$GADGET/strings/0x409/product

  # Create configuration instance for the gadget
  mkdir $CONFIG || echo "  Couldn't create $CONFIG"
  mkdir $CONFIG/strings/0x409 || echo "  Couldn't create $CONFIG/strings/0x409"
  echo $1 >$CONFIG/strings/0x409/configuration || echo "  Couldn't write configuration name"
}

create_config "UAC2"
add_uac2_function "Active" 0x1 0x1

# Check if there's an USB Device Controller
if [ -z "$(ls /sys/class/udc)" ]; then
	echo "  No USB Device Controller available"
	return
fi

# Activate the gadget
echo "$(ls /sys/class/udc | head -1 )" >$GADGET/UDC || echo "  Couldn't write UDC"
