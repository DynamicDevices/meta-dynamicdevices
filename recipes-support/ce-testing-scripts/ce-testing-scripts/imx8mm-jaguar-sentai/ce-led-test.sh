#!/bin/sh

echo Running CE LED testing...

x=0
while [ $x -le 5 ]
do
  path="/sys/class/leds/led${x}"

  echo "127" > $path/brightness

  echo " 255 0" > $path/multi_intensity

  x=$(( $x + 1 ))
done
