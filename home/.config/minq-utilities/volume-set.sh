#! /usr/bin/env bash

set -e

if [ "$#" -ne 1 ]; then
	echo "invalid number of arguments"
	exit 1
fi

amount="$1"

pactl set-sink-volume @DEFAULT_SINK@ ${amount}
