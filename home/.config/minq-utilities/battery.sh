#! /usr/bin/env bash

# TODO make this work with multiple batteries

set -e

name="BAT0"
capacity=$(cat /sys/class/power_supply/${name}/capacity)
state=$(cat /sys/class/power_supply/${name}/status)
echo "${name}:${capacity}:${state}"
