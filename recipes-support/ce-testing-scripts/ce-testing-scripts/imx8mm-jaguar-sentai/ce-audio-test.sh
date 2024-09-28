#!/bin/sh

echo Running CE audio testing...

amixer -D pulse sset Master 30%

while [ TRUE ]
do
  paplay /usr/share/ce-testing/PinkPanther60.wav
done

