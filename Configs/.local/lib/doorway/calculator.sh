#!/usr/bin/env bash
#|- calculator.sh - calculator popup (anyrun rink plugin; was rofi-calc)
# rink handles arithmetic, unit conversion and currency; the launcher
# (Super+A) loads it too — this dedicated flow just skips the other plugins.
anyrun close 2> /dev/null && exit 0
anyrun --plugins librink.so --hide-plugin-info true
