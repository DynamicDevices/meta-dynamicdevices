#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024 NXP

amixer -cmicfilaudio cset name='MICFIL Quality Select' 'High'
amixer -cmicfilaudio cset name='CH0 Volume' '10'

gst-launch-1.0 -q --no-position \
    alsasrc device=$MIC_DEVICE latency-time=16000 ! \
    audioconvert ! \
    audio/x-raw,format=F32LE ! \
    audiocheblimit cutoff=100.0 mode=1 ! \
    queue max-size-buffers=0 leaky=1 ! \
    aecnr.sink_mic \
    imx_ai_aecnr name=aecnr ! \
    audio/x-raw,channels=1,rate=16000,format=F32LE,layout=interleaved ! \
    queue max-size-buffers=0 leaky=1 ! \
    audioconvert ! \
    audio/x-raw,channels=1,rate=16000,format=S32LE,layout=interleaved ! \
    alsasink device=$USB_ACTIVE_DEVICE buffer-time=16000 