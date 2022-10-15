#! /usr/bin/env bash

# package might be called `sysstat` instead

# mpstat | tail -1 | awk '{print $7}'

requested_time="$1"

mpstat --dec=0 "$requested_time" 1 | tail -1 | awk '{print $6}'
	# `--dec` stands for number of decimal places. default is `2`
