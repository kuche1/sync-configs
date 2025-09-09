#! /usr/bin/env bash

set -e

HERE=$(dirname "$BASH_SOURCE")

# this only works if the icon was clicked in `i3blocks`
case "${button}" in
    "") # no event
        ;;
    "4") # mwheelup
        "${HERE}"/volume-set.sh inc-small
        ;;
    "5") # mwheeldown
        "${HERE}"/volume-set.sh dec-small
        ;;
    *) # anything else
        pavucontrol > /dev/null &
        ;;
esac

vol="$(${HERE}/volume-get.sh)"

printf '♪'

if [ "${vol}" -gt 100 ]; then
	printf "<span foreground=\"red\">${vol}</span>"
else
	printf "${vol}"
fi

printf '%%\n'
