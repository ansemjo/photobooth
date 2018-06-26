#!/usr/bin/env bash

# load config
. ./config.sh

# log a message with a bolded timestamp in front, propagate to child shells
log() { printf '\033[%sm[%s]\033[0m %s\n' "${2:-1}" "$(date --utc +%FT%T%Z)" "$1" | tee --append log.txt; }
typeset -fx log

# log an error in bold red
err() { log "$1" "1;31"; }
typeset -fx err

# log an error and exit
fatal() { err "$1"; exit 1; }
typeset -fx fatal

log "starting photobooth"

# find the newest subdirectory
newest-dir() { find "$1" -mindepth 1 -maxdepth 1 -type d -exec ls -d1t {} \+ | head -1; }

# does the photobooth root exist?
[[ -d $PHOTOBOOTH ]] || fatal "$PHOTOBOOTH does not exist!"

# find the newest subdirectory of photobooth folder
DIRECTORY=$(newest-dir "$PHOTOBOOTH")

# error if there is none yet, i.e. $DIRECTORY is empty
[[ -n $DIRECTORY ]] || fatal "couldn't determine newest directory! is $PHOTOBOOTH empty?"

# log directory that is used
log "using $DIRECTORY"

exit 0

# display black screen in background
eog --fullscreen --single-window black.png &

# create directory
mkdir -p "$DIRECTORY"

# Aktivierung des Tethering-Modus der Kamera und Warten auf Bilder
gphoto2 \
  --capture-tethered \
  --filename="$DIRECTORY/$ANLASS-%Y%m%d-%H-%M-%S-%n.%C" \
  --force-overwrite \
  --hook-script=hook.sh
