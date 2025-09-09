#! /usr/bin/env bash

set -euo pipefail

if amixer -D pulse sget Master &> /dev/null ; then
	vol=$(awk -F"[][]" '/Left:/ { print $2 }' <(amixer -D pulse sget Master))
elif amixer sget Master &> /dev/null ; then
	vol=$(awk -F"[][]" '/Left:/ { print $2 }' <(amixer sget Master))
fi

vol="${vol::-1}"
# delete the last character - `%`

echo "${vol}"
