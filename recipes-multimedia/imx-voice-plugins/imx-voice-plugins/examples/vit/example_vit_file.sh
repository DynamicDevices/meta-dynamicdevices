# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 NXP

gst-launch-1.0 \
               filesrc location=input.wav ! wavparse ! \
               audioconvert ! audioresample ! \
               tee name=t ! fakesink \
               t. ! imxvit