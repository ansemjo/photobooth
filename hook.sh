#!/usr/bin/env bash

# fail on any error
set -e

# load functions
. ./library.sh

case "$ACTION" in

	init)

		# log directory that is used
		log "using $DIRECTORY"

		# copy the frame that is displayed first
		log "copy startscreen"
		cp -f "$STARTSCREEN" "$DIRECTORY/$STARTSCREEN"

	;;

	start)

		# start refreshing slideshow in the background
		log "initialize background slideshow"
		feh \
			--hide-pointer \
			--fullscreen \
			--zoom fill \
			--randomize \
			--reload 1 \
			--slideshow-delay 3 \
			"$DIRECTORY" &

	;;

	download)

		rm -f "$DIRECTORY/$STARTSCREEN"
		killall -USR1 feh

		# display new photo on top
		log "display $ARGUMENT"
		feh \
			--hide-pointer \
			--fullscreen \
			--zoom fill \
			--cycle-once \
			--slideshow-delay 6 \
			"$ARGUMENT" &

	;;

	stop)

		log "killing all remaining feh processes"
		killall feh

	;;

	*) err "unknown action: $ACTION"; exit 1 ;;

esac