#!/bin/sh
set -e

#
# Sentai Initial Production Test.
# To be operated by technician at manufacturing house.
#
# NOTES:
#
#  - This test script must be run as the root user. e.g.
#
#    # sudo production-test.sh [enter password]
#
# Process:
#
# - Flash current manufacturing image. NOTE: THIS MUST NOT BE RELEASED TO CUSTOMER WITHOUT SECURING
# - Run this production test and ensure all tests pass
# - Agree to secure device by entering 'Y' when asked
#

#
# Definitions
#

VERSION=0.1

#
# Test script
#

# Check if running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root by running this command with sudo 'sudo production-test.sh' and entering the password"
  exit
fi

echo -e "Stopping Sentai application\n"
docker stop sentaispeaker-SentaiSpeaker-1

echo -e "Running Sentai Production Test - Version ${VERSION}\n"

# (1) Show board infomation
echo -e "(1) Record the board information for your records"
board-info.sh

# (2) Run LED Testing
echo -e "\n"
read -r -p "(2) Run LED tests? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "You should see red, green, blue and white LEDs cycling\n"
    test-leds-hb.sh
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit -1
fi

echo -e "\n"
read -r -p "Did you see the correct LED colours with none missing? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit -1
fi

# (3) Run humidity sensor Testing
echo -e "\n"
read -r -p "(3) Run humidity sensor tests? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
    sensors || true
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit -1
fi

echo -e "\n"
read -r -p "Did a reasonable temperature and humidity value display? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit -1
fi

# (4) Program STUSB4500
echo -e "\n"
read -r -p "(4) Program STUSB4500? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
    stusb4500-utils write --file /lib/firmware/stusb4500.dat
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit -1
fi

echo -e "\n"
read -r -p "Did the programming step complete successfully ? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit -1
fi

# (5) Input button testing
echo -e "\n"
read -r -p "(5) Test button input? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    if [ ! -d /sys/class/gpio/gpio102 ]
    then
      echo 102 > /sys/class/gpio/export
    fi
    echo -e "Press and hold down the button within 5s\n"
    sleep 5
    BUTTONVALUE=`cat /sys/class/gpio/gpio102/value`
    echo -e ">>${BUTTONVALUE}<<\n"
    # Button is active LO
    if [ "${BUTTONVALUE}" -eq "1" ]
    then
        echo -e "TEST FAILED - BUTTON PRESS NOT DETECTED\n"
        exit -1
    fi
    echo -e "Button press detected. Release the button now\n"
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit -1
fi


# (6) Audio Testing
echo -e "\n"
read -r -p "(6) Perform Audio Testing [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "Setting the audio levels\n\n"
    su -c "pactl set-sink-mute 0 0" fio
    su -c "pactl set-sink-volume 0 60%" fio
    amixer -c 0 set 'CH0' 100
    amixer -c 0 set 'CH1' 100
    amixer -c 0 set 'CH2' 0
    amixer -c 0 set 'CH3' 0
    amixer -c 0 set 'CH4' 0
    amixer -c 0 set 'CH5' 0
    amixer -c 0 set 'CH6' 0
    amixer -c 0 set 'CH7' 0
    echo -e "Done setting the audio levels\n\n"

    echo -e "Now playing an audio sample\n"
    su -c "paplay /usr/share/board-scripts/board-testing-now-starting-up.wav" fio
    read -r -p "Did you hear the audio play back [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo -e "Audio playback worked\n"
    else
        echo TEST FAILED
        exit -1
    fi

    amixer -c 0 set 'CH0' 100
    amixer -c 0 set 'CH1' 0

    echo -e "\n\nNow recording 5s audio on FIRST microphone channel\n"
    read -p "Press RETURN key to start recording and then start counting up in a clear voice"
    echo -e "\nStarted recording...\n"

    su -c "arecord -Dhw:0 -c2 -f s16_le -r48000 -d5 test-l.wav" fio

    read -p "Done recording. Press RETURN key to play back recording"

    echo -e "\n\nNow playing back recording\n"
    su -c "paplay test-l.wav" fio
    rm -f test-l.wav

    read -r -p "Did you hear the audio play back [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo -e "Audio playback worked\n"
    else
        echo TEST FAILED
        exit -1
    fi

    amixer -c 0 set 'CH0' 0
    amixer -c 0 set 'CH1' 100

    echo -e "\n\nNow recording 5s audio on SECOND microphone channel\n"
    read -p "Press RETURN key to start recording and then start counting up in a clear voice"
    echo -e "\nStarted recording...\n"

    su -c "arecord -Dhw:0 -c2 -f s16_le -r48000 -d5 test-r.wav" fio

    read -p "Done recording. Press RETURN key to play back recording"

    sox test-r.wav -c 1 test-r-1chan.wav

    echo -e "\n\nNow playing back recording\n"
    su -c "paplay test-r-1chan.wav" fio
    rm -f test-r.wav
    rm -f test-r-1chan.wav

    read -r -p "Did you hear the audio play back [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo -e "Audio playback worked\n"
    else
        echo TEST FAILED
        exit -1
    fi
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit -1
fi

# (7) BLE Testing
echo -e "\n"
read -r -p "(7) Perform Bluetooth BLE Testing [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "Now scanning for bluetooth devices\n"
    bluetoothctl power on
    bluetoothctl --timeout 5 scan on
    bluetoothctl power off
    echo -e "\n^^^ You should have seen a number of MAC addresses and device names\n"
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit -1
fi

echo -e "\n"
read -r -p "Did you see a number of bluetooth MAC addresses and device names ? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit -1
fi

# Check we are on the Foundries cloud

# (8) Secure device
echo -e "\n"
read -r -p "(8) Are you ready to secure the device? NOTE YOU CAN ONLY DO THIS ONCE [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "\n"
    echo SECURING DEVICE
    echo -e "- Set secure password for fio user"
    sudo -u fio set-fio-passwd.sh
    sudo rm /etc/salt
    echo -e "- Enable firewall"
    enable-firewall.sh
    echo -r "- Disable production WiFi connection [TODO]"
#    nmcli c del SentaiProduction
elif [[ "$response" =~ ^([yY][eE][yY])$ ]]
then
    echo TEST FAILED
    exit -1
fi

# Check app container is running

echo -e "Production test successful\n"
date > /etc/.production-test-successful
su -c "paplay /usr/share/board-scripts/tests-all-completed.wav" fio
exit 0
