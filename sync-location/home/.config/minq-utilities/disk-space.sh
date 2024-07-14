#! /usr/bin/env bash

### doesn't quite work on ZFS
#
# free_space=$(df -h / | tail -1 | awk '{print $4}')
# free_space=$(echo "$free_space" | python3 -c 'print(input().replace(",", "."))')
# #echo "porn folder: $free_space"
# echo "$free_space"

free=$(zpool list | tail -1 | awk '{print $4}')
total=$(zpool list | tail -1 | awk '{print $2}')

echo "free:$free/$total"
