#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2025 NXP

amixer -cmicfilaudio cset name='MICFIL Quality Select' 'High'
amixer -cmicfilaudio cset name='CH0 Volume' '0'
amixer -c wm8962audio set 'Headphone' '125'

gst-launch-1.0  \
    udpsrc port=4020 caps = "application/x-rtp,encoding-name=SPEEX,media=audio,clock-rate=16000" ! \
    rtpjitterbuffer ! \
    rtpspeexdepay ! \
    speexdec ! \
    audioconvert ! \
    queue ! \
    audio/x-raw,channels=1,rate=16000,format=S32LE,layout=interleaved ! \
    alsasink device=hw:wm8962audio \
    alsasrc device=hw:micfilaudio ! \
    audio/x-raw,channels=1,rate=16000,format=S32LE,layout=interleaved ! \
    queue ! \
    audioconvert ! \
    speexenc ! \
    rtpspeexpay ! \
    udpsink host=$1 port=4020 async=false
