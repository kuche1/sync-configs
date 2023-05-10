#! /usr/bin/env bash

set -e

STEP=0.1
MAX=1.0
MIN=0.1

get_brightness(){
    xrandr --verbose | awk '/Brightness/ { print $2; exit }'
}

get_xrandr_output(){ # TODo export this fnc
    xrandr --verbose | awk '/ connected / { print $1; exit }'
}

set_brightness(){
    value="$1"
    xrandr --output $(get_xrandr_output) --brightness $value
}

action="$1"

case "$action" in
    get)
        get_brightness
        ;;
    inc)
        cur=$(get_brightness)
        new=$(python3 -c "print(min($MAX, $cur + $STEP))")
        set_brightness $new
        ;;
    dec)
        cur=$(get_brightness)
        new=$(python3 -c "print(max($MIN, $cur - $STEP))")
        set_brightness $new
        ;;
    *)
        echo "Invalid action \`$action\`"
        exit 1
esac
