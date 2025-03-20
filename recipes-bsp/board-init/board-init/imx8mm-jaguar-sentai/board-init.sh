#!/bin/sh

# Make sure /tmp/presence FIFO is created before anything else happens
# as otherwise it's possible the containers start up and then error as
# they are trying to mount a non-existent folder
mkfifo -m666 /tmp/presence || 1

# Show some life to the user
leds-proof-of-life.sh &
