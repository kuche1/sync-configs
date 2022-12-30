#! /usr/bin/env bash

set -e

here=$(dirname "$BASH_SOURCE")

# this only works if the icon was clicked in `i3blocks`
case "${button}" in
    "") # no event
        ;;
    "4") # mwheelup
        "${here}"/volume-set.sh inc-small
        ;;
    "5") # mwheeldown
        "${here}"/volume-set.sh dec-small
        ;;
    *) # anything else
        pavucontrol > /dev/null &
        ;;
esac

#awk -F"[][]" '/Left:/ { print $2 }' <(amixer sget Master)
vol=$(awk -F"[][]" '/Left:/ { print $2 }' <(amixer -D pulse sget Master))
vol="${vol::-1}"
	# delete the last character - `%`

printf '♪'

if [ "${vol}" -gt 100 ]; then
	printf "<span foreground=\"red\">${vol}</span>"
else
	printf "${vol}"
fi

printf '%%\n'
