#! /usr/bin/env bash

# TODO make this work if mic is `front left` and `front right` instead of `mono`

# this works for `mono`
#awk -F"[][]" '/Mono:/ { print $4 }' <(amixer set Capture toggle)

# this works for `front right`
amixer set Capture toggle | tail -1 | awk -F"[][]" '{print $4}'
