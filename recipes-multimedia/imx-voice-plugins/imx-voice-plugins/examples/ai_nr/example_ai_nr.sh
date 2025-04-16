#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024 NXP

amixer -cmicfilaudio cset name='MICFIL Quality Select' 'High'
amixer -cmicfilaudio cset name='CH0 Volume' '14'

gst-launch-1.0 -q --no-position \
    alsasrc device=$MIC_DEVICE ! \
    queue ! \
    audioconvert ! \
    imx_ai_nr model=large ! \
    audio/x-raw,channels=1,rate=16000,format=S32LE ! \
    alsasink device=$USB_ACTIVE_DEVICE
