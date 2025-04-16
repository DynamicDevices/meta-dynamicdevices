# 1 - GStreamer voice plugins for imx platforms

## plugins in this package

| Name              | Description                                                                  |
|-------------------|------------------------------------------------------------------------------|
| imx_ai_nr         | NXP AI-based single microphone noise reduction                               |
| imx_ai_aecnr      | NXP AI-based single microphone acoustic echo canceller and noise suppressor  |
| imxvit            | NXP wakeword and voice commands detection engine                             |
| imx_ai_dual_aecnr | NXP AI-based simultaneous far-end and local echoes and noise canceller       |

  
## releases notes


IMX_VOICE_PLUGINS_DEMO_0_6
- Added support of i.MX8MQ for most of the plugins
- new `imx_ai_dual_aecnr` plugin for both local and remote echo cancellation and noise reduction

IMX_VOICE_PLUGINS_DEMO_0_5
- More i.MX devices supported for all plugins (see full list below)
- new `imxvit` plugin performing wakeword and voice commands recognition
- all plugins now use gstreamer logging mechanism instead of prints on the console (except optionally for `imxvit` detection results)
- `imx_ai_nr` support multiple instances with timeout
- `imx_ai_nr` safe to toggle `bypass` option when pipeline is running
- `imx_ai_aecnr`: better handling of EOS events (for file-based tests with both mic and echo ref input files)
- `imx_ai_aecnr`: evaluation timeout set to 1h

IMX_VOICE_PLUGINS_DEMO_0_4
- fix "bypass" option that couldn't be dynamically changed more than once
- rename `imxsemodel` to `imx_ai_nr`
- rename `imxaecml` to `imx_ai_aecnr`
- add "large" model for `imx_ai_nr` (previous model is now identified as "small")
- increase `imx_ai_nr` evaluation timeout

IMX_VOICE_PLUGINS_DEMO_0_3
- add "small" model for `imxaecml`
- introduce new `imxsemodel` plugin
- remove constraint on input buffer size (internal buffering to support any input size)

Previous demos v0.1 and v0.2
- early development versions of `imxaecml`  plugin

## supported devices


The plugins are compatible with these devices:

| plugins compatibility |
|-----------------------|
| i.MX 8M Nano          |
| i.MX 8M Mini          |
| i.MX 8M Plus          |
| i.MX 8MQ (\*)         |
| i.MX 91               |
| i.MX 93               |
| i.MX 95               |

(\*): except `imxvit` 

The examples provided in the package have been tested on a selected list of EVK (see detail for each example below).
Some changes might be needed in the example's script to make it compatible with the board you will use.
The name of the audio interfaces might change, or the volume applied on some interfaces might need to be adjusted.


## dependencies compatibility

| version  |  BSP                   | Gstreamer | TFlite (\*) |
|--------- | ---------------------- |-----------|-------------|
| DEMO 0.5 | Linux 6.6.52_2.2.0     | 1.24.7    | 2.16.2      |
| DEMO 0.4 | Linux 6.6.36_2.1.0     | 1.24.0    | 2.16.2      |
| DEMO 0.3 | Linux 6.6.36_2.1.0     | 1.24.0    | 2.16.2      |

(\*): Only some plugins depends on TFLite. See applicable dependencies in each plugin's section below. 
  
## setup

Copy the package on the device's file system, then uncompress and install the shared objects in the Gstreamer plugins location.

```shell
unzip imx-voice-plugins.zip
cp gst-plugin/libgstimx* /usr/lib/gstreamer-1.0/
```
At this stage the plugins are available to gstreamer.
`gst-inspect-1.0` tool can be used to check correct installation and to get more information about the plugins.

Some pipeline examples are provided in `examples` folder, see instruction below for each plugin.
  
----------------------

# 2 - AI Noise Reduction Plugin

## Plugin information

```shell
Plugin Details:
  Name                     imx_ai_nr
  Filename                 /usr/lib/gstreamer-1.0/libgstimx_ai_nr.so

Pad Templates:
  SINK template: 'sink'
    Capabilities: audio/x-raw, channels: 1, rate: 16000, format: S32LE
  
  SRC template: 'src'
    Capabilities: audio/x-raw, channels: 1, rate: 16000, format: S32LE
```

**Properties:**

`model`: can take value "small" or "large" to select the model used. If unspecified the large model is used by default. large model has better performances than small one, but consume more MHz.

`bypass`: when set to true, the incoming buffers are directly passed from sink pad to src pad without any processing. To be used for debug.

`tuning-com`: name of the com device to be used to communicate with debug tool. Should be left null for normal operation.

**Dependencies:**

- GStreamer
  
## Example 1 - microphone over USB

These 2 examples use a single microphone from the EVK, process the data with AI NR and send the processed stream over USB to the host.
From the host, the EVK is recognized as "i.MX" microphone, so the audio processed by AI NR can be recorded through this interface by any audio recording application.
One example use large model and the other one use the small model.

Run large model example:

```shell
cd examples/ai_nr/
source ../usb_gadget_utils/setup_usb_gadget.sh
bash example_ai_nr.sh
```

Run small model example:

```shell
cd examples/ai_nr/
source ../usb_gadget_utils/setup_usb_gadget.sh
bash example_ai_nr_small.sh
```

tested on: MCIMX93-EVK, 8MNANOLPD4-EVK
  
## Example 2 - file processing

This example reads audio from an "input.wav" file, process it through AI NR and writes "output.wav". This can be used to evaluate performances of the algorithm on known test patterns.

```shell
cd examples/ai_nr/
bash example_ai_nr_file.sh
```

tested on all supported devices.

----------------------

# 3 - AI Acoustic Echo Canceler and Noise Reduction Plugin

## Plugin information

```shell
Plugin Details:
  Name                     imx_ai_aecnr
  Filename                 /usr/lib/gstreamer-1.0/libgstimx_ai_aecnr.so

Pad Templates:
  SINK template: 'sink_mic'
    Capabilities: audio/x-raw, channels: 1, rate: 16000, format: F32LE

  SINK template: 'sink_remote'
    Capabilities: audio/x-raw, channels: 1, rate: 16000, format: F32LE

  SRC template: 'src_remote'
    Capabilities: audio/x-raw, channels: 1 rate: 16000 format: F32LE
```

`sink_remote` pad is optional. If not connected to any source, or if connected but no data buffer is provided to it, then the plugin will behave as noise reductor only.

**Properties:**

`model`: can take value "small" or "large" to select the model used. If unspecified the large model is used by default. large model has better performances than small one, but consume more MHz.

`rx-padding`: Fill Rx with 0 if no data received. Mandatory for use-cases where remote source is not providing data continuously. Enabled by default.

`bypass`: when set to true, the incoming buffers on sink_mic pas are directly passed to src_remote pad without any processing, while incoming buffers on "sink_remote" are dropped. To be used for debug.


**Dependencies:**

- GStreamer
- TensorflowLite
  
## Algorithm details

### Inputs

The model has been trained with the following input levels:

- sink_mic input:
  - nearend speech: [-80, -60] dBFS
  - noise floor: -96 dBFS
- sink_remote input:
  - farend reference: [-35, -15] dBFS

Note that the best results from AECML will be achieved when inputs are in the specified ranges.
This is especially important for the "small" model which can generate unexpected results for signals out of the specified range, while "large" model is more tolerant.

Also the model has been trained with a delay between echo reference and microphone input of maximum 250ms. Perfromances will be degraded when the acoustic delay is higher.

The model expects an high-pass filter to be applied on incoming data on  `sink_mic` pad with 100Hz cut-off frequency. See examples below using `audiocheblimit` Gstreamer plugin for that purpose.

### Output

In the current version the models have been trained to only suppress echo and noise, thus the output signal range will be closer to the nearend range.
Also, AGC is not included in the plugin.
  
## Example 1 - USB speaker phone with echo canceller

These 2 examples take input from a single microphone from the EVK, and the echo reference from the USB input, process the data with AI AECNR and send the processed stream over USB to the host.
One example use large model and the other one use the small model.

From the host, device is visible as:

- i.MX Speaker: Speaker where Host sends signal to be played on device's speaker.
- i.MX Active: Microphone (1 channel) where Host receives enhanced speech. This is the default interface that should be used for this use-case.
- i.MX PassThrough: Microphone (1 channel) where Host receives unprocessed speech. To be used for debug and check unprocessed audio from microphone.
- i.MX Debug: Microphone (2 channels) where Host receives both enhanced and unprocessed speech. To be used for debug to more easily compare unprocessed microphone audio with processed output.
Any application capable of playing and recording audio can be used on the host to send/receive audio from the device by using these audio interfaces, e.g. an audio player/recorder or a conference-call application.

Run large model example:

```shell
cd examples/ai_aecnr/
source ../usb_gadget_utils/setup_usb_gadget_debug.sh
bash example_ai_aecnr.sh
```

Run small model example:

```shell
cd examples/ai_aecnr/
source ../usb_gadget_utils/setup_usb_gadget_debug.sh
bash example_ai_aecnr_small_model.sh
```

tested on: MCIMX93-EVK, 8MNANOLPD4-EVK

## Example 2 - microphone over USB - noise reduction only without echo cancelation

This example use a single microphone from the EVK, process the data with AI AECNR and send the processed stream over USB to the host.
No signal is provided as echo reference, resulting in noise reduction only without echo cancelation
From the host, the EVK is recognized as "i.MX" microphone, so the audio processed by AI AECNR can be recorded through this interface by any audio recording application.

Run example:

```shell
cd examples/ai_aecnr/
source ../usb_gadget_utils/setup_usb_gadget.sh
bash example_ai_aecnr_no_echo_ref.sh
```

tested on: MCIMX93-EVK, 8MNANOLPD4-EVK

## Example 3 - file processing

This example reads audio from "mic.wav" (microphone input) and "rx.wav" (echo reference) files,  process through AI AECNR and writes "output.wav". This can be used to evaluate performances of the echo cancellation and noise reduction on known test patterns.

```shell
cd examples/ai_aecnr/
bash example_ai_aecnr_file.sh
```

tested on all supported devices.

----------------------

# 4 - VIT Plugin


## Plugin information

```shell
Plugin Details:
  Name                     imxvit
  Filename                 /usr/lib/gstreamer-1.0/libgstimxvit.so

Pad Templates:
  SINK template: 'sink'
    Capabilities: audio/x-raw channels: 1 rate: 16000 format: S16LE
```

The plugin performs voice recognition for wakeword and voice commands as defined by either the default embedded model or by a custom one defining custom wakeword or voice commands. Contact voice@nxp.com for model customization.
Voice detection are reported as messages sent to the pipeline, so an application running the pipeline can easily catch them to perform any applicable actions. Optionally detection results can be printed on the console to simplify test and debug.

**Properties:**

`model-path`: Path to custom VIT model (binary format). If not provided a default NXP english model is used.

`silent`: when set to true, the voice detection results will not be printed on console, message will still be sent to pipeline.

`voice-commands`: when enabled, voice commands will be detected after a wakeword detection, this is the default behavior. When disabled, only wakeword detection is performed.


**Dependencies:**

- GStreamer
  
## Example 1 - wakeword and voice commands detection with default model

This example take input from 1 digital microphones from the EVK and process the data with VIT to detect wakeword and voice commands as defined by the default model embedded in the plugin.
Wakeword and voice commands detections are printed on the console.

Run example:

```shell
cd examples/vit/
bash example_vit.sh
```

tested on: MCIMX93-EVK, 8MNANOLPD4-EVK
  
## Example 2 - wakeword and voice commands detection with custom model

This example take input from 1 digital microphones from the EVK and process the data with VIT to detect wakeword and voice commands as defined by a custom model built by the online model generation tool.
Wakeword and voice commands detections are printed on the console.

```shell
cd examples/vit/
bash example_vit_custom_model.sh
```

tested on: MCIMX93-EVK, 8MNANOLPD4-EVK

## Example 3 - wakeword detection triggering an application action

This example take input from 1 digital microphones from the EVK and process the data with VIT to detect wakeword (but not the voice commands) as defined by the default model embedded in the plugin.
It shows how the application can catch the detection message from imxvit plugin to perform some actions. In this example, when the wakeword is detected, the audio from the microphone is routed to the codec and can be heard on a speaker connected on the jack connector. After a timeout, the audio is re-routed to imxvit for another wakeword detection.
The name of the coded on which to play the audio should be passed as an argument to the script.

with default codec (on i.MX93 EVK)
```shell
cd examples/vit/
python3 example_vit_ww.py 
```

specifying the codec (here on i.MX8MN)
```shell
cd examples/vit/
python3 example_vit_ww.py --codec wm8524audio
```

tested on: MCIMX93-EVK, 8MNANOLPD4-EVK

## Example 4 - wakeword and voice commands detection from an audio file

This examples shows how imxvit can be used to detect wakeword and voice commands in an audio file.

```shell
cd examples/vit/
bash example_vit_file.sh
```
tested on all supported devices except i.MX8MQ.


# 5 - AI Double Acoustic Echo Canceler and Noise Reduction Plugin

## Plugin information

```shell
Plugin Details:
  Name                     imx_ai_dual_aecnr
  Filename                 /usr/lib/gstreamer-1.0/libgstimx_ai_dual_aecnr.so

Pad Templates:
  SINK template: 'sink_mic'
    Capabilities: audio/x-raw, channels: 1, rate: 16000, format: F32LE

  SINK template: 'sink_remote'
    Capabilities: audio/x-raw, channels: 1, rate: 16000, format: F32LE

  SRC template: 'src_remote'
    Capabilities: audio/x-raw, channels: 1, rate: 16000, format: F32LE

  SRC template: 'src_speaker'
    Capabilities: audio/x-raw, channels: 1, rate: 16000, format: F32LE

```

**Properties:**

`model`: can take value "small" or "large" to select the model used. If unspecified the large model is used by default. large model has better performances than small one, but consume more MHz.

`bypass-local`: bypass the local echo cancelation processing. Incoming data on `sink_mic` pad are pushed without processing on `src_remote` pad. To be used for debug.

`bypass-remote`: bypass the remote echo cancelation processing. Incoming data on `sink_remote` pad are pushed without processing on `src_speaker` pad. To be used for debug.

`remote-delay`: estimation of the round-trip delay between the 2 devices. Precision should be around 250ms, but this value must not be higher than the actual audio round trip delay. Typically for a VoIP solution, the ping time between the 2 devices is a good approximation, assuming there is no extensive buffering on any side.

`mic-gain`: dB gain applied on `sink_mic` data before processing. Same gain is removed after processing before output on `src_remote` pad.

`rx-gain`: dB gain applied on `sink_remote` data before processing. Same gain is removed after processing before output on `src_speaker` pad.

`local-echo-gain`: dB gain applied on local echo reference.

`remote-echo-gain`: dB gain applied on remote echo reference.


**Dependencies:**

- GStreamer
- TensorflowLite
  
## Algorithm details

### Inputs

The models used in both echo cancellers have been trained with the following input levels:

- sink_mic input:
  - nearend speech: [-80, -60] dBFS
  - noise floor: -96 dBFS
- sink_remote input:
  - farend reference: [-35, -15] dBFS

The `*-gain` properties should be used to match the signal levels with these ranges. 

Also the models have been trained with a delay between echo reference and microphone input of maximum 250ms.
The local echo delay (time between playing a sound on `src_speaker` and capturing its echo on `sink_mic`) is typically within this range. The remote echo delay (time between playing a sound on `src_remote` and capturing its echo on `sink_remote`) may be much higher since it includes all the communication layer with the 2 devices (e.g. VoIP). The property `remote-delay` should be used to compensate this delay and make it fit in the [0-250ms] range.

The model expects an high-pass filter to be applied on incoming data on both `sink_mic` and `sink_remote` pads with 100Hz cut-off frequency. See examples below using `audiocheblimit` Gstreamer plugin for that purpose.

### Output

The output signal range will be close to the input range. i.e. 'src_remote' will have similar range than 'sink_mic' and 'src_speaker' same range than 'sink_remote'.


### Known limitation

The ability of the model to suppress echo is highly dependent on the input speech level, especially for the `small` model which has a very narrow range of input level for which the performances are correct.
There is currently no automatic gain control implemented in the plugin, so the `*-gain` properties should be used to adjust input signals levels for model input.
But with the `small` model, even on a correctly tuned system, a change in the signal level by e.g. speaking louder and closer to the microphone can make the echo cancelation not to work as expected.

An AGC is planned to be supported in a future release to remove this constraint on the input levels.

  
## Example 1 - VoIP with dual echo canceller

This example involves 2 devices connected over IP and exchanging encoded audio. On both devices: one digital microphone is used to capture audio and the codec is used to play audio on a speaker connected to the jack.
One of this device does not perform any echo cancelation, the second one use the imx_ai_dual_aecnr to suppress echo from both sides of the communication.


Device A (note that imx-voice-plugins is not needed on this one, you may want to only copy the pipeline example on this device):

```shell
cd examples/ai_dual_aecnr/
bash example_voip_no_aec.sh xx.xx.xx.xx
```
`xx.xx.xx.xx` is the IP address of device B


Device B - this is the one actually demonstrating the imx-ai-dual-aecnr plugin:

```shell
cd examples/ai_dual_aecnr/
python3 example_ai_dual_aecnr_voip.py --udp_host xx.xx.xx.xx --model large --delay yyyy
```
`xx.xx.xx.xx` is the IP address of device A
`yyyy` is the estimation of round trip delay between the 2 boards in ms. You can start with the `ping` delay, and increase it progressively until echo is correctly removed.

You can use `--dump` option if you want input and ouput audio to be recorded. Files are placed in `/tmp/` folder, they will be overwritten on each restart of the pipeline, and deleted on reboot. This can be useful to tune the gains of imx_ai_dual_aecnr in the example script.

This python script provides an input console to simply disable AEC processings:
enter `l` to toggle local AEC processing
enter `r` to toggle remote AEC processing
enter `q` to quit the example.

tested on: MCIMX93-EVK

## Example 2 - file processing

This example reads audio from an "input.wav" stereo file, 1st channel is used as microphone input, 2nd as rx input. After processing by `imx_ai_dual_aecnr`, the produced audio is stored in 2 files: `output_tx.wav` and `output_speaker.wav`.
This can be used to evaluate performances of the algorithm on known test patterns, or to more easily tune gains and delay parameters.

```shell
cd examples/ai_dual_aecnr/
bash example_ai_dual_aecnr_file.sh
```

tested on all supported devices.
