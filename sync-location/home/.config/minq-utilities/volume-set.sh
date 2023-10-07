#! /usr/bin/env bash

set -e

ME="$BASH_SOURCE"

#AMOUNT='2.0%'
#AMOUNT_SMALL='1.0%'
AMOUNT='2%'
AMOUNT_SMALL='1%'

# TODO
# if [ "$#" -ne 1 ]; then
# 	echo "invalid number of arguments"
# 	exit 1
# fi

type="$1"

case "${type}" in
	'inc')
		#amount="+$AMOUNT"
		amount="$AMOUNT+"
		;;
	'inc-small')
		#amount="+$AMOUNT_SMALL"
		amount="$AMOUNT_SMALL+"
		;;
	'dec')
		#amount="-$AMOUNT"
		amount="$AMOUNT-"
		;;
	'dec-small')
		#amount="-$AMOUNT_SMALL"
		amount="$AMOUNT_SMALL-"
		;;
	'amount')
		amount="$2"
		;;
	'fix')
		"${ME}" 'inc-small'
		"${ME}" 'dec-small'
		exit 0
		;;
	*)
		echo "ERROR: invalid type: ${type}"
		exit 1
		;;
esac

#pactl set-sink-volume @DEFAULT_SINK@ "${amount}"
amixer -D pulse set Master "${amount}" > /dev/null
