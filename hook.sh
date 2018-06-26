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
		FILES=$(ls -1 "$DIRECTORY/" | wc -l)

		# copy first frame if directory is empty
		[[ $FILES -eq 0 ]] \
			&& log "copy startscreen" \
			&& cp -f "$STARTSCREEN" "$DIRECTORY/" \
			|| true

	;;

	start)

		# start refreshing slideshow in the background
		log "initialize background slideshow"
		feh \
			--hide-pointer \
			--fullscreen \
			--zoom fill \
			--randomize \
			--reload 2 \
			--slideshow-delay $SLIDESHOW_DELAY \
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
			--slideshow-delay $SNAPSHOT_DELAY.5 \
			"$ARGUMENT" &
		sleep $SNAPSHOT_DELAY && kill -USR1 "$(cat photobooth.pid)" &

	;;

	stop)

		log "killing all remaining feh processes"
		killall feh &

		log "remove pid file"
		rm photobooth.pid

	;;

	*) err "unknown action: $ACTION"; exit 1 ;;

esac