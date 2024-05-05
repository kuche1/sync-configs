#! /usr/bin/env bash

set -euo pipefail

STEP=0.1
MAX=1.0
MIN=0.1

HERE=$(dirname -- $(readlink -f -- "$BASH_SOURCE"))

get_brightness(){
    xrandr --verbose | awk '/Brightness/ { print $2; exit }'
}

set_brightness(){
    value="$1"
    xrandr --output $("$HERE"/get-xrandr-output.sh) --brightness $value
}

action="$1"

case "$action" in
    get)
        get_brightness
        ;;
    set)
    	set_brightness "$2"
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
