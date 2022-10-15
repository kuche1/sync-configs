#! /usr/bin/env bash

here=$(dirname "$0")

# this only works if the icon was clicked in `i3blocks`
case "${button}" in
    "") # no event
        ;;
    "4") # mwheelup
        "${here}"/volume-increase-5.sh
        ;;
    "5") # mwheeldown
        "${here}"/volume-decrease-5.sh
        ;;
    *) # anything else
        pavucontrol > /dev/null &
        ;;
esac

awk -F"[][]" '/Left:/ { print $2 }' <(amixer sget Master)
