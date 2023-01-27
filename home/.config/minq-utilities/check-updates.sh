#! /usr/bin/env bash

regular_updates=$(
	(
		(checkupdates --version >/dev/null && checkupdates) ;
		(apt --version >/dev/null && apt list --upgradable 2>/dev/null) ;
	) | wc -l
)

special_updates=$(
	(
		(paru --version >/dev/null && paru -Qua) ;
	) | wc -l
)

printf "r${regular_updates}s${special_updates}\n"
