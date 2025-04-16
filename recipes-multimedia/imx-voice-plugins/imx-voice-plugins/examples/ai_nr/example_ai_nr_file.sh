#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024 NXP

gst-launch-1.0 -q --no-position \
    filesrc location=input.wav ! wavparse ! \
    audioconvert ! audioresample ! \
    imx_ai_nr ! \
    audio/x-raw,channels=1,rate=16000,format=S32LE ! \
    wavenc ! filesink location=output.wav
