#! /usr/bin/env bash

regular_updates=$(
	(
		(checkupdates --version >/dev/null && checkupdates) ;
		(apt --version >/dev/null          && apt list --upgradable) ; # TODO this needs to be reduces by 1
	) | wc -l
)

special_updates=$(
	(
		(paru --version >/dev/null && paru -Qua) ;
	) | wc -l
)

number_of_packages=$(
	(
		(pacman -Q) ;
		(dpkg --get-selections) ;
	) | wc -l
)

percent_of_system_that_needs_update=$(
	echo "scale=0 ; 100*(${regular_updates}+${special_updates})/${number_of_packages}" | bc
)

printf "${percent_of_system_that_needs_update}%%r${regular_updates}s${special_updates}\n"
