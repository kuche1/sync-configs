#! /usr/bin/env bash

# TODO this doesn't work on the very first boot

# this only works for `mono`
#awk -F"[][]" '/Mono:/ { print $4 }' <(amixer set Capture toggle)

all_output=$(amixer get Capture toggle)
last_line=$(tail -1 <<< "${all_output}")
on_or_off=$(awk -F"[][]" '{print $4}' <<< "${last_line}")

case "${on_or_off}" in
	"on")
		fg_col='blue'
		;;
	"off")
		fg_col='red'
		;;
	*)
		fg_col='yellow'
		on_or_off="${last_line}"
		;;
esac

echo "<span foreground=\"${fg_col}\">${on_or_off}</span>"
