#! /usr/bin/env bash

(transmission-gtk --help && (transmission-gtk || exit $?)) ||
qbittorrent
