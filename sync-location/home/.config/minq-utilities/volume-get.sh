#! /usr/bin/env bash

set -euo pipefail

#awk -F"[][]" '/Left:/ { print $2 }' <(amixer sget Master)
vol=$(awk -F"[][]" '/Left:/ { print $2 }' <(amixer -D pulse sget Master))

vol="${vol::-1}"
# delete the last character - `%`

echo "${vol}"
