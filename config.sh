#!/usr/bin/env bash

# we depend on dropbox to upload pictures to the cloud™ in the background
# give the dropbox root here:
DROPBOX=~/Dropbox

# photobooth root, where the newest directory will be used
PHOTOBOOTH="$DROPBOX/Fotobox"

# override for local testing only!
mkdir -p /tmp/photobooth/$(date --utc +%s)
PHOTOBOOTH=/tmp/photobooth