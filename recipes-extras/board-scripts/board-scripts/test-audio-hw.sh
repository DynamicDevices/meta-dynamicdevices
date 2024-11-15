#
# Plays a known DTMF wav file and records at the same time, then checks for the DTMF
#

echo Running hardware in the loop audio test

tries=1
while [ $tries -le 3 ]
do
  echo Attempt ${tries}
  rm -f audio-test.wav
  echo Recording audio
  arecord -c 2 -r 8000 -f S16_LE -D pulse audio-test.wav -d 5 &
  sleep 1
  echo Playing audio file
  aplay /usr/share/board-scripts/dtmf-182846.wav
  sleep 2
  DECODED=`dtmf2num audio-test.wav | grep "DTMF numbers" | cut -c 18-`
  echo We got $DECODED
  rm audio-test.wav
  if [ "$DECODED" == "182846" ]; then
    echo SUCCESS
    exit 0
  fi
  tries=$(( $tries + 1 ))
done

echo FAILURE
exit 1
