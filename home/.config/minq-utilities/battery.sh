#! /usr/bin/env bash

# TODO make this work with multiple batteries

bat=$(cat /sys/class/power_supply/BAT0/capacity)
if [ "$bat" != "" ]; then
	echo "BAT0:$bat"
fi
