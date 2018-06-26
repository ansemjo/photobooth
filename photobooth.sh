#!/usr/bin/env bash

# load config and library
. ./config.sh
. ./library.sh

log "starting photobooth"

# does the photobooth root exist?
[[ -d $PHOTOBOOTH ]] || fatal "$PHOTOBOOTH does not exist!"

# find the newest subdirectory of photobooth folder
export DIRECTORY=$(newest-dir "$PHOTOBOOTH")

# error if there is none yet, i.e. $DIRECTORY is empty
[[ -n $DIRECTORY ]] || fatal "couldn't determine newest directory! is $PHOTOBOOTH empty?"

# log directory that is used
log "using $DIRECTORY"

# copy start screen
cp -f "$STARTSCREEN" "$DIRECTORY/"

# start tethering
gphoto2 \
  --capture-tethered \
  --filename="$DIRECTORY/%Y%m%d-%H%M%S-%04n.%C" \
  --hook-script=hook.sh
