#!/usr/bin/env bash

# supporting functions which shall be used by
# the various scripts

# log a message with a bolded timestamp in front, propagate to child shells
log() { printf '\033[%sm[%s]\033[0m %s\n' "${2:-1}" "$(date --utc +%FT%T%Z)" "$1" | tee --append "$LOGFILE"; }
typeset -fx log

# log an error in bold red
err() { log "$1" "1;31"; }
typeset -fx err

# log an error and exit
fatal() { err "$1"; exit 1; }
typeset -fx fatal

# find the newest subdirectory
newest-dir() { find "$1" -mindepth 1 -maxdepth 1 -type d -exec ls -d1t {} \+ | head -1; }
