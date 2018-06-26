#!/usr/bin/env bash

printf '%s %s\n' "$(date --utc +%FT%T%Z)" "STARTING PHOTOBOOTH"

DROPBOX=~/Dropbox
ANLASS="TEST"
DIRECTORY="$DROPBOX/Fotobox/$ANLASS"

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
