#
# Plays a known DTMF wav file and records at the same time, then checks for the DTMF
#

echo Setting up volume
pactl set-sink-mute alsa_output.default 100%
pactl set-sink-volume alsa_output.default 60%

amixer -c micfilaudio set 'CH0' 100
amixer -c micfilaudio set 'CH1' 100
amixer -c micfilaudio set 'CH2' 0
amixer -c micfilaudio set 'CH3' 0
amixer -c micfilaudio set 'CH4' 0
amixer -c micfilaudio set 'CH5' 0
amixer -c micfilaudio set 'CH6' 0
amixer -c micfilaudio set 'CH7' 0

echo Setting to record on Microphone 1
amixer -c micfilaudio set 'CH0' 100
amixer -c micfilaudio set 'CH1' 0

arecord -c 2 -r 8000 -f S16_LE -D pulse audio-test-microphone-1.wav -d 5 &
sleep 1

echo Playing audio file to record
paplay /usr/share/board-scripts/AudioTest-Microphone-One.mp3

sleep 5

echo Playing replay notification
paplay /usr/share/board-scripts/AudioTest-Recording-Will-Now-Play-Back.mp3

sleep 5

echo Playing recording
paplay pulse audio-test-microphone-2.wav

echo Setting to record on Microphone 2
amixer -c micfilaudio set 'CH0' 0
amixer -c micfilaudio set 'CH1' 100

arecord -c 2 -r 8000 -f S16_LE -D pulse audio-test-microphone-2.wav -d 5 &
sleep 1

sleep 5
echo Playing audio file to record
paplay /usr/share/board-scripts/AudioTest-Microphone-Two.mp3

sleep 5

echo Playing replay notification
paplay /usr/share/board-scripts/AudioTest-Recording-Will-Now-Play-Back.mp3

sleep 5

echo Playing recording
paplay audio-test-microphone-1.wav

sleep 5

rm audio-test-microphone-1.wav
rm audio-test-microphone-2.wav

echo Done
