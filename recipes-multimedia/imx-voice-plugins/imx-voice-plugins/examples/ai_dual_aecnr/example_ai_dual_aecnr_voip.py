#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2025 NXP


import argparse
import gi
import signal
import logging
import os
import time
import threading
import queue

gi.require_version("Gst", "1.0")
from gi.repository import Gst, GLib  # noqa


class AECPipeline:
    def __init__(self, udp_host='', dump=False, model='large', delay=500):
        self.running = False
        self.mainloop = None
        self.pipe_name = "Dual_AI_AECNR_Pipeline"

        pipe = ' '
        # Mic Input
        pipe += ' alsasrc device=hw:micfilaudio ! '
        pipe += ' audio/x-raw,channels=1,rate=16000,format=S32LE,layout=interleaved ! '
        pipe += ' tee name=mic_in ! '
        pipe += ' audioconvert ! '
        pipe += ' audio/x-raw,format=F32LE ! '
        pipe += ' audiocheblimit cutoff=100.0 mode=1 ! '
        pipe += ' aec.sink_mic '

        # Network input + audio decoding
        pipe += ' udpsrc port=4020 caps = "application/x-rtp,encoding-name=SPEEX,media=audio,clock-rate=16000" ! '
        pipe += ' rtpjitterbuffer ! '
        pipe += ' rtpspeexdepay ! '
        pipe += ' speexdec ! '
        pipe += ' tee name=rx_in ! '
        pipe += ' audioconvert ! '
        pipe += ' audio/x-raw,format=F32LE ! '
        pipe += ' audiocheblimit cutoff=100.0 mode=1 ! '
        pipe += ' aec.sink_remote '

        # Dual AECNR 
        pipe += f' imx_ai_dual_aecnr name=aec model={model} bypass_local=false bypass_remote=false remote_delay={delay} mic_gain=0.0 rx_gain=-5.0 remote_echo_gain=15.0 local_echo_gain=10.0 '

        # audio encode + output to network
        pipe += ' aec.src_remote ! '
        pipe += ' audio/x-raw,channels=1,rate=16000,format=F32LE,layout=interleaved ! '
        pipe += ' audioconvert ! '
        pipe += ' tee name=tx_out ! queue max-size-buffers=1 ! '
        pipe += ' speexenc ! '
        pipe += ' rtpspeexpay ! '
        pipe += f' udpsink host={udp_host} port=4020 async=false '

        # output to speaker
        pipe += ' aec.src_speaker ! '
        pipe += ' audio/x-raw,channels=1,rate=16000,format=F32LE,layout=interleaved ! '
        pipe += ' audioconvert ! '
        pipe += ' tee name=spk_out ! queue max-size-buffers=1  ! '
        pipe += ' audio/x-raw,channels=1,rate=16000,format=S32LE,layout=interleaved ! '
        pipe += ' alsasink device=hw:wm8962audio '

        # Dump to files
        if dump :
            pipe += ' mic_in. ! queue ! wavenc ! filesink location="/tmp/mic_in.wav" '
            pipe += ' rx_in. ! queue ! wavenc ! filesink location="/tmp/rx_in.wav" '
            pipe += ' tx_out. ! queue ! wavenc ! filesink location="/tmp/tx_out.wav" '
            pipe += ' spk_out. ! queue ! wavenc ! filesink location="/tmp/spk_out.wav" '

        print(pipe)

        format = "%(asctime)s.%(msecs)03d %(levelname)s:\t%(message)s"
        datefmt = "%Y-%m-%d %H:%M:%S"
        logging.basicConfig(level=logging.INFO, format=format, datefmt=datefmt)

        if not Gst.is_initialized():
            Gst.init(None)

        self.pipeline = Gst.parse_launch(pipe)
        self.bus = self.pipeline.get_bus()

        self.app_src = self.pipeline.get_by_name('app_src')
        self.dual_aecnr = self.pipeline.get_by_name('aec')
        self.aecnr_remote_bypass = False
        self.aecnr_local_bypass = False

        self.q = queue.SimpleQueue()
        self.q_len = 0

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


    def apply_aecnr_bypass(self):
        print(f" Local AEC: {not self.aecnr_local_bypass} - remote AEC: {not self.aecnr_remote_bypass} ")
        self.dual_aecnr.set_property("bypass_remote", self.aecnr_remote_bypass);
        self.dual_aecnr.set_property("bypass_local", self.aecnr_local_bypass);

    def toggle_remote_aecnr_bypass(self):
        self.aecnr_remote_bypass = not self.aecnr_remote_bypass
        self.apply_aecnr_bypass()

    def toggle_local_aecnr_bypass(self):
        self.aecnr_local_bypass = not self.aecnr_local_bypass
        self.apply_aecnr_bypass()

    def input_keyboard(self):
        while True:
            key_in = input("[l,r,q]: ")
            if key_in.lower() == 'q':  # Exit condition
                print("Exiting input listener.")
                self.mainloop.quit()
                break
            if key_in.lower() == 'r':
                self.toggle_remote_aecnr_bypass()
            if key_in.lower() == 'l':
                self.toggle_local_aecnr_bypass()

    def run_input_keyboard_thread(self):
        # Start the input listener in a separate thread
        listener_thread = threading.Thread(target=self.input_keyboard)
        listener_thread.start()



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='double AI AECNR (remote and local) example pipeline')
    parser.add_argument('--udp_host', type=str,
                        help='address of UDP host', default='192.168.1.20')
    parser.add_argument('--model', type=str,
                        help='model large or small', default='large')
    parser.add_argument('--dump', action='store_true',
                        help='dump input/output audio to files', default=False)
    parser.add_argument('--delay', type=int,
                        help='network delay between the 2 devices', default=500)
    args = parser.parse_args()

    # Set PDM mic quality to its maximum
    os.system("amixer -cmicfilaudio cset name='MICFIL Quality Select' 'High'")
    # increase PDM mic range
    os.system("amixer -cmicfilaudio cset name='CH0 Volume' '2'")
    # increase speaker volume
    os.system("amixer -c wm8962audio set 'Headphone' '125'")
    pipe = AECPipeline(udp_host=args.udp_host, dump=args.dump, model=args.model, delay=args.delay)
    pipe.run_input_keyboard_thread()
    pipe.run()


