#!/bin/bash

# simple helper to feed resolve.sh from log and output to colorizer with config

# pipe input from log, pipe output to colorizer
#
tail -f /var/log/gw/syslog.log | ./resolve.sh | grcat /usr/share/grc/conf.log
