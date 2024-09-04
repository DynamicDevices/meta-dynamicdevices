#
# Test LEDS rotate RGBW colours
#
while [ 1 ]
do

x=0
while [ $x -le 5 ]
do
  path="/sys/class/leds/led${x}"

  echo "255" > $path/brightness

  echo "255 0 0" > $path/multi_intensity
  sleep 0.05
  echo "0 0 0" > $path/multi_intensity

  x=$(( $x + 1 ))
done

x=0
while [ $x -le 5 ]
do
  path="/sys/class/leds/led${x}"

  echo "255" > $path/brightness

  echo "0 255 0" > $path/multi_intensity
  sleep 0.05
  echo "0 0 0" > $path/multi_intensity

  x=$(( $x + 1 ))
done

x=0
while [ $x -le 5 ]
do
  path="/sys/class/leds/led${x}"

  echo "255" > $path/brightness

  echo "0 0 255" > $path/multi_intensity
  sleep 0.05
  echo "0 0 0" > $path/multi_intensity

  x=$(( $x + 1 ))
done

x=0
while [ $x -le 5 ]
do
  path="/sys/class/leds/led${x}"

  echo "255" > $path/brightness

  echo "255 255 255" > $path/multi_intensity
  sleep 0.05
  echo "0 0 0" > $path/multi_intensity

  x=$(( $x + 1 ))
done

done
