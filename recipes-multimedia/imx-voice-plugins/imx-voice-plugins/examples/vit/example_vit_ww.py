#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 NXP


import argparse
import gi
import signal
import logging
import os
import time
import threading

gi.require_version("Gst", "1.0")
from gi.repository import Gst, GLib  # noqa


class VITPipeline:
    def __init__(self,codec='wm8962audio'):
        self.running = False
        self.mainloop = None
        self.pipe_name = "VITPipeline"

        pipe = ' '
        # Mic Input
        pipe += ' alsasrc device=hw:micfilaudio,0 ! '
        pipe += ' output-selector name=mic_in '
        # VIT
        pipe += ' mic_in.src_0 ! '
        pipe += ' audioconvert ! '
        pipe += ' imxvit name=vit voice-commands=false silent=true '
        # Output to speaker
        pipe += ' mic_in.src_1 ! '
        pipe += ' audioconvert ! audioresample ! '
        pipe += ' audio/x-raw,channels=2,rate=32000,format=S32LE,layout=interleaved ! '
        pipe += f' alsasink device=hw:{codec} '

        print(pipe)

        format = "%(asctime)s.%(msecs)03d %(levelname)s:\t%(message)s"
        datefmt = "%Y-%m-%d %H:%M:%S"
        logging.basicConfig(level=logging.INFO, format=format, datefmt=datefmt)

        if not Gst.is_initialized():
            Gst.init(None)

        self.pipeline = Gst.parse_launch(pipe)
        self.bus = self.pipeline.get_bus()
        self.bus.add_signal_watch()
        self.bus.connect("message", self.on_bus_message)

        self.mic_in = self.pipeline.get_by_name('mic_in')
        self.pad_src_0 = self.mic_in.get_static_pad("src_0")
        self.pad_src_1 = self.mic_in.get_static_pad("src_1")

        self.mic_in.set_property("active-pad", self.pad_src_0);


        signal.signal(signal.SIGINT, self.sigint_handler)

    def start(self):
        self.running = True
        self.pipeline.set_state(Gst.State.PLAYING)

    def stop(self):
        self.running = False
        self.bus.remove_signal_watch()

    def run(self):
        self.start()
        self.mainloop = GLib.MainLoop()
        self.mainloop.run()
        self.stop()

    def sigint_handler(self, signal, frame):
        print("handling interrupt.")
        self.mainloop.quit()

    def timeout(self):
        print("timeout - restarting VIT processing")
        self.mic_in.set_property("active-pad", self.pad_src_0);


    def on_bus_message(self, bus, message, name=None):

        if (message.src.name == 'vit'):
            s = message.get_structure()
            det_res = s.get_value("detection_result")
            det_id  = s.get_value("detected_id")
            det_str = s.get_value("detected_str")
            if (det_res == 1) :
                print(det_str)
                self.mic_in.set_property("active-pad", self.pad_src_1);
                threading.Timer(10, self.timeout).start()


parser = argparse.ArgumentParser(description='VIT example pipeline')
parser.add_argument('--codec', type=str,
                    help='name of the codec to use to output audio', default='wm8962audio')
args = parser.parse_args()

print (args.codec)
# Set PDM mic quality to its maximum
os.system("amixer -cmicfilaudio cset name='MICFIL Quality Select' 'High'")
pipe = VITPipeline(codec=args.codec)
pipe.run()

