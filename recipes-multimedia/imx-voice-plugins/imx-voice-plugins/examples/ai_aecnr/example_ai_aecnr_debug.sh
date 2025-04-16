#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 NXP

amixer -cmicfilaudio cset name='MICFIL Quality Select' 'High'
amixer -cmicfilaudio cset name='CH0 Volume' '10'

gst-launch-1.0 -q --no-position \
    alsasrc device=$MIC_DEVICE latency-time=16000 ! \
    audioconvert ! \
    audio/x-raw,format=F32LE ! \
    audiocheblimit cutoff=100.0 mode=1 ! \
    tee name=mic_src ! \
    queue max-size-buffers=0 leaky=1 ! \
    aecnr.sink_mic \
    alsasrc device=$USB_REMOTE_DEVICE latency-time=16000 ! \
    audio/x-raw,channels=1,rate=16000,format=S32LE,layout=interleaved ! \
    audioconvert ! \
    audio/x-raw,format=F32LE ! \
    tee name=remote_src ! \
    queue leaky=1 ! \
    aecnr.sink_remote \
    imx_ai_aecnr name=aecnr model=large ! \
    audio/x-raw,channels=1,rate=16000,format=F32LE,layout=interleaved ! \
    tee name=aecnr_out ! \
    queue max-size-buffers=0 leaky=1 ! \
    audioconvert ! \
    audio/x-raw,channels=1,rate=16000,format=S32LE,layout=interleaved ! \
    alsasink device=$USB_ACTIVE_DEVICE buffer-time=16000 \
    remote_src. ! \
    queue leaky=1 ! \
    audioconvert ! \
    audioresample ! \
    audio/x-raw,channels=2 ! \
    alsasink device=$SPEAKER_DEVICE buffer-time=16000 \
    mic_src. ! \
    queue max-size-buffers=0 leaky=1 ! \
    audioconvert ! \
    audio/x-raw,channels=1,rate=16000,format=S32LE,layout=interleaved ! \
    alsasink device=$USB_PASSTHROUGH_DEVICE buffer-time=16000 \
    interleave name=usb_debug ! \
    queue max-size-buffers=0 leaky=1 ! \
    alsasink device=$USB_DEBUG_DEVICE buffer-time=16000 \
    mic_src. ! \
    queue max-size-buffers=0 leaky=1 ! \
    audioconvert ! \
    audio/x-raw,channels=1,rate=16000,format=S32LE,layout=interleaved ! \
    audioconvert ! \
    "audio/x-raw,channels=1,channel-mask=(bitmask)0x2" ! \
    usb_debug.sink_0 \
    aecnr_out. ! \
    queue max-size-buffers=0 leaky=1 ! \
    audioconvert ! \
    audio/x-raw,channels=1,rate=16000,format=S32LE,layout=interleaved ! \
    audioconvert ! \
    "audio/x-raw,channels=1,channel-mask=(bitmask)0x1" ! \
    usb_debug.sink_1
