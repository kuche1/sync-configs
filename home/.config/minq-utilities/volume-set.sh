#! /usr/bin/env bash

set -e

ME="$BASH_SOURCE"

# TODO
# if [ "$#" -ne 1 ]; then
# 	echo "invalid number of arguments"
# 	exit 1
# fi

type="$1"

case "${type}" in
	'inc')
		amount='+5.0%'
		;;
	'inc-small')
		amount='+1.0%'
		;;
	'dec')
		amount='-5.0%'
		;;
	'dec-small')
		amount='-1.0%'
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

pactl set-sink-volume @DEFAULT_SINK@ "${amount}"
