#! /usr/bin/env bash

free -h | tail -1 | awk '{print $2}'
