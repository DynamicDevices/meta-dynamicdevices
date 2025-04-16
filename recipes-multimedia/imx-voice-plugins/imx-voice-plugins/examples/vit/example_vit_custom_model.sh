# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 NXP

amixer -cmicfilaudio cset name='MICFIL Quality Select' 'High'

gst-launch-1.0 --no-position \
               alsasrc device=hw:micfilaudio,0 ! \
               audioconvert ! \
               imxvit model-path=./VIT_Model_en.bin 
