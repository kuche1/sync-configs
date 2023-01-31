#! /usr/bin/env bash

#amixer set Capture toggle
	# for some reason this didn't work on my latest installation

pactl set-source-mute @DEFAULT_SOURCE@ toggle
