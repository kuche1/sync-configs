#! /usr/bin/env bash

awk -F"[][]" '/Mono:/ { print $4 }' <(amixer set Capture toggle)
