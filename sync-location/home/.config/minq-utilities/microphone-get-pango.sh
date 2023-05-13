#! /usr/bin/env bash

here=$(dirname "$BASH_SOURCE")

# this only works for `mono`
#awk -F"[][]" '/Mono:/ { print $4 }' <(amixer set Capture toggle)

# wtf this stopped working
# all_output=$(amixer get Capture toggle)
# last_line=$(tail -1 <<< "${all_output}")
# on_or_off=$(awk -F"[][]" '{print $4}' <<< "${last_line}")

source=$(pactl info | grep "Default Source" | cut -f3 -d" ")
mute_info=$(pactl list sources | grep -A 10 "${source}" | grep 'Mute: ' | cut -f2 -d' ')
case "${mute_info}" in
	'yes')
		on_or_off='off'
		;;
	'no')
		on_or_off='on'
		;;
	*)
		on_or_off="unknown mute state: ${mute_info}"
		;;
esac

# this only works with `pango` markdown
case "${on_or_off}" in
	"on")
		fg_col='green'
		;;
	"off")
		fg_col='red'
		;;
	*)
		fg_col='yellow'
		on_or_off="ERROR: ${on_or_off}"
		;;
esac

# this only works if the icon was clicked in `i3blocks`
if [ "${button}" != "" ]; then
	"${here}"/microphone-set.sh > /dev/null
fi

echo "<span foreground=\"${fg_col}\">${on_or_off}</span>"
