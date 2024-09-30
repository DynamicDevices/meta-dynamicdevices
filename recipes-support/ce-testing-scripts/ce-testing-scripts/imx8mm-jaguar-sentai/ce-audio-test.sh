#!/bin/sh

sleep 10

echo Running CE audio testing...

while [ TRUE ]
do
  amixer -D pulse sset Master 30%
  paplay /usr/share/ce-testing/PinkPanther60.wav
done

