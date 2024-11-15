#
# Plays a known DTMF wav file and records at the same time, then checks for the DTMF
#

echo Running hardware in the loop audio test
echo Recording audio
arecord audio-test.wav &
PID=$!
sleep 1
echo Playing audio file
aplay /usr/share/board-scripts/dtmf-1234.wav
sleep 1
kill $PID
DECODED=dtmf2num audio-test.wav
echo We got $DECODED

