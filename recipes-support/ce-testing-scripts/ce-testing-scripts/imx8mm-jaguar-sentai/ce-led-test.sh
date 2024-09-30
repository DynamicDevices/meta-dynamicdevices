#!/bin/sh

echo Running CE LED testing...

path="/sys/class/leds/led${x}"

echo "127" > $path/brightness
echo "0 255 0" > $path/multi_intensity
