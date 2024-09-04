#
# Pulses a coloured heartbeat - R, G, B, W
#

c=0

while [ $c -le 3 ]
do

echo $c
x=0

if [ $c -eq 0 ]; then
  echo RED
elif [ $c -eq 1 ]; then
  echo GREEN
elif [ $c -eq 2 ]; then
  echo BLUE
elif [ $c -eq 3 ]; then
  echo WHITE
fi

# Set colour
while [ $x -le 5 ]
do
  path="/sys/class/leds/led${x}"

  if [ $c -eq 0 ]; then
    echo "255 0 0" > $path/multi_intensity
  elif [ $c -eq 1 ]; then
    echo "0 255 0" > $path/multi_intensity
  elif [ $c -eq 2 ]; then
    echo "0 0 255" > $path/multi_intensity
  elif [ $c -eq 3 ]; then
    echo "255 255 255" > $path/multi_intensity
  fi

  x=$(( $x + 1 ))
done

# Heatbeat up and down

i=0
while [ $i -le 255 ]
do
  x=0
  while [ $x -le 5 ]
  do
    path="/sys/class/leds/led${x}"
    echo "$i" > $path/brightness
    x=$(( $x + 1 ))
  done

  i=$(( $i + 5 ))
done

while [ $i -ge 0 ]
do
  x=0
  while [ $x -le 5 ]
  do
    path="/sys/class/leds/led${x}"
    echo "$i" > $path/brightness
    x=$(( $x + 1 ))
  done

  i=$(( $i - 5 ))
done

c=$(( $c + 1 ))

done
