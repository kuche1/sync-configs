#! /usr/bin/env bash

swap=$(free -h | tail -1 | awk '{print $2}')
echo ${swap} | python3 -c 'print(input().replace(",",".")[:-1])'
