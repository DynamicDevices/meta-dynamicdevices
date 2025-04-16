#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2025 NXP

#Input file must have 2 tracks:
# - 1st: microphone input
# - 2nd: Rx input

gst-launch-1.0 \
      filesrc location=input.wav ! wavparse ! \
      audioconvert ! audioresample ! \
      audio/x-raw,channels=2,rate=16000,format=F32LE,layout=interleaved ! \
      deinterleave name=d \
      d.src_0 ! \
      audiocheblimit cutoff=100.0 mode=1 ! \
      dual_aecnr.sink_mic \
      d.src_1 ! \
      audiocheblimit cutoff=100.0 mode=1 ! \
      dual_aecnr.sink_remote \
      imx_ai_dual_aecnr name=dual_aecnr model=large \
      dual_aecnr.src_speaker ! \
      queue ! \
      audio/x-raw,channels=1,rate=16000,format=F32LE,layout=interleaved ! \
      wavenc ! filesink location=output_speaker.wav \
      dual_aecnr.src_remote ! \
      queue ! \
      audio/x-raw,channels=1,rate=16000,format=F32LE,layout=interleaved ! \
      wavenc ! filesink location=output_tx.wav