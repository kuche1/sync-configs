#! /usr/bin/env bash

free_space=$(df -h / | tail -1 | awk '{print $4}')
echo "Porn folder: $free_space"
