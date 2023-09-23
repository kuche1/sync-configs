#! /usr/bin/env bash

free_space=$(df -h / | tail -1 | awk '{print $4}')
echo "porn folder: $free_space"
