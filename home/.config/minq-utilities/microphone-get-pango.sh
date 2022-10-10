#! /usr/bin/env bash

here=$(dirname "$0")

# this only works for `mono`
#awk -F"[][]" '/Mono:/ { print $4 }' <(amixer set Capture toggle)

all_output=$(amixer get Capture toggle)
last_line=$(tail -1 <<< "${all_output}")
on_or_off=$(awk -F"[][]" '{print $4}' <<< "${last_line}")

# this obly works with `pango` markdown
case "${on_or_off}" in
	"on")
		fg_col='green'
		;;
	"off")
		fg_col='red'
		;;
	*)
		fg_col='yellow'
		on_or_off="ERROR:${last_line}"
		echo "${all_output}" > /tmp/microphone-widget-error-log
		;;
esac

# this only works if the icon was clicked in `i3blocks`
if [ "${button}" != "" ]; then
	"${here}"/microphone-set.sh > /dev/null
fi

echo "<span foreground=\"${fg_col}\">${on_or_off}</span>"
