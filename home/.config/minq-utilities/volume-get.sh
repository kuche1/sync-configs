#! /usr/bin/env bash

here=$(dirname "$BASH_SOURCE")

# this only works if the icon was clicked in `i3blocks`
case "${button}" in
    "") # no event
        ;;
    "4") # mwheelup
        "${here}"/volume-set.sh +5%
        ;;
    "5") # mwheeldown
        "${here}"/volume-set.sh -5%
        ;;
    *) # anything else
        pavucontrol > /dev/null &
        ;;
esac

#awk -F"[][]" '/Left:/ { print $2 }' <(amixer sget Master)
awk -F"[][]" '/Left:/ { print $2 }' <(amixer -D pulse sget Master)
