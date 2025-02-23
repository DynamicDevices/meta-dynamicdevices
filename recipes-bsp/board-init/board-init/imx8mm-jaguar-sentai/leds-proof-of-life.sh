#!/bin/sh

#
# Test LEDS rotate RGBW colours
#

# Set colour
BRIGHTNESS=0
while [ $BRIGHTNESS -le 255 ]
do
  x=0
  while [ $x -le 5 ]
  do
    path="/sys/class/leds/led${x}"
    echo -e "$BRIGHTNESS" > $path/brightness
    echo "255 255 255" > $path/multi_intensity
    x=$(( $x + 1 ))
  done

  BRIGHTNESS=$(( $BRIGHTNESS + 1 ))
  sleep 0.01
done
