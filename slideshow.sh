#!/usr/bin/env bash

printf '%s %s\n' "$(date --utc +%FT%T%Z)" "PREVIEW NEW PICTURE"

# newly downloaded photo
CURRENT=$1
DIRNAME=$(dirname "$CURRENT")



# kill running slideshows
killall feh

# display new photo, after that cycle slideshow
feh \
  --hide-pointer \
  --fullscreen \
  --auto-zoom \
  --cycle-once \
  --slideshow-delay 3 \
  "$CURRENT" \
&& feh \
  --hide-pointer \
  --fullscreen \
  --auto-zoom \
  --randomize \
  --reload 5 \
  --slideshow-delay 3 \
  "$DIRNAME/"
