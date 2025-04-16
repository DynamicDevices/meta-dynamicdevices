#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 NXP

gst-launch-1.0  \
                  filesrc location=mic.wav ! wavparse ! \
                  audioconvert ! audioresample ! \
                  aecnr.sink_mic \
                  filesrc location=rx.wav ! wavparse ! \
                  audioconvert ! audioresample ! \
                  aecnr.sink_remote \
                  imx_ai_aecnr name=aecnr model=large rx_padding=false ! \
                  audio/x-raw,channels=1,rate=16000,format=F32LE ! \
                  wavenc ! filesink location=output.wav