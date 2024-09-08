#!/bin/bash -e
user=$(whoami)

fl=$(find /proc -maxdepth 2 -user "$user" -name environ -print -quit)
for i in {1..5}
do
  fl=$(find /proc -maxdepth 2 -user "$user" -name environ -newer "$fl" -print -quit)
done

export DBUS_SESSION_BUS_ADDRESS
DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS "$fl" | cut -d= -f2-)

pactl load-module module-native-protocol-unix socket=/tmp/pulseaudio.socket auth-anonymous=true
