#! /usr/bin/env bash

if [ "${button}" != "" ]; then
    dde-calendar > /dev/null &
fi

date '+%Y-%m-%d w%V %H:%M:%S'
# if u want sunday as first day of the week u can use `%U` instead of `%V`
