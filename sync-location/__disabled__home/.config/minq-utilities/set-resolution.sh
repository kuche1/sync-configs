#! /usr/bin/env bash

set -e

HERE=$(dirname -- $(readlink -f -- "$BASH_SOURCE"))

xrandr --output $("$HERE"/get-xrandr-output.sh) --mode 1920x1080 --rate 144.00 --primary
