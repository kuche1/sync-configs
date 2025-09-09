#! /usr/bin/env bash

set -e
set -o xtrace

#DEVICE=alsa_input.usb-C-Media_Electronics_Inc._Redragon_Gaming_Headset-00.mono-fallback:capture_MONO
#DEVICE=alsa_input.usb-Logitech_G635_Gaming_Headset_00000000-00.mono-fallback:capture_MONO
DEVICE_INPUT=$(pw-link -o | grep mono-fallback)

DEVICE_OUTPUT_FL=alsa_output.usb-C-Media_Electronics_Inc._Redragon_Gaming_Headset-00.analog-stereo:playback_FL
#DEVICE_OUTPUT_FL=alsa_output.usb-Logitech_G635_Gaming_Headset_00000000-00.analog-stereo:monitor_FL # doesn't work

DEVICE_OUTPUT_FR=alsa_output.usb-C-Media_Electronics_Inc._Redragon_Gaming_Headset-00.analog-stereo:playback_FR
#DEVICE_OUTPUT_FR=alsa_output.usb-Logitech_G635_Gaming_Headset_00000000-00.analog-stereo:monitor_FR # doesn't work

# create sinks and virtual mic
pactl load-module module-null-sink media.class=Audio/Sink           sink_name=audio-sharing-sink                    channel_map=stereo
pactl load-module module-null-sink media.class=Audio/Sink           sink_name=CONFIG-ONLY-audio-sharing-sync-volume channel_map=stereo
pactl load-module module-null-sink media.class=Audio/Source/Virtual sink_name=minq-virtualmic                       channel_map=front-left,front-right

# redirect real mic to virtual mic
pw-link ${DEVICE_INPUT} minq-virtualmic:input_FL
	# find device by running `pw-link -o`

# redirect regular sink to lower volume sink
pw-link audio-sharing-sink:monitor_FL CONFIG-ONLY-audio-sharing-sync-volume:playback_FL
pw-link audio-sharing-sink:monitor_FR CONFIG-ONLY-audio-sharing-sync-volume:playback_FR

# redirect lower volume sink to virtual mic
pw-link CONFIG-ONLY-audio-sharing-sync-volume:monitor_FL minq-virtualmic:input_FL
pw-link CONFIG-ONLY-audio-sharing-sync-volume:monitor_FR minq-virtualmic:input_FR

# set volume on lower volume sink
pactl set-sink-volume CONFIG-ONLY-audio-sharing-sync-volume 50%

# connect regular sink to headphones
pw-link audio-sharing-sink:monitor_FL ${DEVICE_OUTPUT_FL}
pw-link audio-sharing-sink:monitor_FR ${DEVICE_OUTPUT_FR}
