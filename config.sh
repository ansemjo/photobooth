#!/usr/bin/env bash

# we depend on dropbox to upload pictures to the cloud™ in the background
# give the dropbox root here:
export DROPBOX=~/Dropbox

# photobooth root, where the newest directory will be used
export PHOTOBOOTH="$DROPBOX/Fotobox"

# startscreen file
export STARTSCREEN="start.png"

# logging file
export LOGFILE="log.txt"

# override for local testing only!
#mkdir -p /tmp/photobooth/$(date --utc +%s)
#export PHOTOBOOTH=/tmp/photobooth