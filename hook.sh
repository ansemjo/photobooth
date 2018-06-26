#!/usr/bin/env bash

# fail on any error
set -e

# load functions
. ./library.sh

case "$ACTION" in

	init)

		# log directory that is used
		log "using $DIRECTORY"

		# count files in directory
		FILES=$(ls -la "$DIRECTORY/" | wc -l)

		# copy first frame if directory is empty
		[[ $FILES -eq 0 ]] \
			&& log "copy startscreen" \
			&& cp -f "$STARTSCREEN" "$DIRECTORY/"

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
		
		# save pid of background slideshow
		PID=$!
		log "background slideshow PID: $PID"
		printf '%s' "$PID" > photobooth.pid

	;;

	download)

		rm -f "$DIRECTORY/$STARTSCREEN"
		
		# display new photo on top
		log "display $ARGUMENT"
		feh \
			--hide-pointer \
			--fullscreen \
			--zoom fill \
			--cycle-once \
			--slideshow-delay 6 \
			"$ARGUMENT" &
		sleep 5.8 && kill -USR1 "$(cat photobooth.pid)" &

	;;

	stop)

		log "killing all remaining feh processes"
		killall feh &

		log "remove pid file"
		rm photobooth.pid

	;;

	*) err "unknown action: $ACTION"; exit 1 ;;

esac