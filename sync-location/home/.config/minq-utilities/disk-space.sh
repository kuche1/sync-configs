#! /usr/bin/env bash

free_space=$(df -h / | tail -1 | awk '{print $4}')
free_space=$(echo "$free_space" | python3 -c 'print(input().replace(",", "."))')
echo "porn folder: $free_space"
