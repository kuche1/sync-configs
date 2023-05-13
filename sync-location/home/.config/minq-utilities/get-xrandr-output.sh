#! /usr/bin/env bash

set -e

xrandr --verbose | awk '/ connected / { print $1; exit }'
