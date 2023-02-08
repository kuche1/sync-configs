#! /usr/bin/env bash

#(librewolf --version && librewolf) ||
#(firefox --version && firefox)

(librewolf --help && (librewolf $@ ; exit $?)) ||
(firefox --help && (firefox -P default $@ ; exit $?))
# TODO on ubuntu it seems to be called `default` (not sure, can't double-check)
# TODO on arch it's called `default-release`
