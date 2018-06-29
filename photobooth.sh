#!/usr/bin/env bash

# switch to directory of script
export THISSCRIPT=$(readlink -f "$0")
export THISDIRECTORY=$(dirname "$THISSCRIPT")
cd "$THISDIRECTORY"

# ------ CONFIGURATION ------

# user to be used. must be a logged in user to display feh correctly but can be a uid
# uid 1000 is usually the first user
export USER=1000

# fix if feh doesn't display .. we probably need to use the first display
export DISPLAY=:0

# we depend on dropbox to upload pictures to the cloud™ in the background
export PHOTOBOOTH=~/Dropbox/Fotobox
export PHOTOBOOTH=/tmp/Fotobox

# gphoto filename template
export FILENAME_TEMPLATE='%Y%m%d-%H%M%S-%04n.%C'

# startscreen and logging file
export STARTSCREEN="start.png"
export LOGFILE="log.txt"

# picture delays
export SLIDESHOW_DELAY=3
export SNAPSHOT_DELAY=6

# ------ HELPER FUNCTIONS ------

# log a message with a bolded timestamp in front, propagate to child shells
log() { printf '\033[%sm[%s]\033[0m %s\n' "${2:-1}" "$(date --utc +%FT%T%Z)" "$1" | tee --append "$LOGFILE"; }
# log an error in bold red
err() { log "$1" "1;31"; }
# log an error and exit
fatal() { err "$1"; exit 1; }
# redirect output streams to logfile
stdlog() { while read line; do log "$line" "1;34"; done }
# find the newest subdirectory
newest-dir() { find "$1" -mindepth 1 -maxdepth 1 -type d -exec ls -d1t {} \+ | head -1; }

# ------ MAIN SCRIPT ------

case "$ACTION" in

  # udev hook when adding device
  add)

    # udev fires two add events .. silently exit on one
    [[ -n $DRIVER ]] && exit 0;
    
    log "new $ID_VENDOR_FROM_DATABASE camera attached"

    # we are probably root here .. change to user
    if [[ $EUID -eq 0 ]]; then

      # if user given as uid, find appropriate username
      [[ $USER =~ ^[0-9]+$ ]] && export USER=$(id -un $USER)

      # change log ownership as long as we are root
      chown "$USER" "$LOGFILE"

      log "we are root. re-executing $THISSCRIPT as $USER"
      exec su "$USER" "$THISSCRIPT"
    fi

    # does the photobooth root exist?
    [[ -d $PHOTOBOOTH ]] || fatal "$PHOTOBOOTH does not exist!"

    # find the newest subdirectory of photobooth folder
    export DIRECTORY=$(newest-dir "$PHOTOBOOTH")

    # error if there is none yet, i.e. $DIRECTORY is empty
    [[ -n $DIRECTORY ]] || fatal "couldn't determine newest directory! is $PHOTOBOOTH empty?"

    # so that hooks know they are running from gphoto
    export THIS_IS_GPHOTO_CALLING=yes

    # wait a moment
    env | stdlog
    sleep 1

    # start tethering
    gphoto2 \
      --capture-tethered \
      --filename="$DIRECTORY/$FILENAME_TEMPLATE" \
      --hook-script="$THISSCRIPT" \
      2>&1 1>/dev/null | stdlog

    log "gphoto exited. bye!"

  ;;

  # gphoto is initialising tethered capture
	init)

    # should be called by gphoto only
    [[ $THIS_IS_GPHOTO_CALLING == "yes" ]] || fatal "not calling from gphoto hook!"

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

  # gphoto is starting tethered capture
	start)

    # should be called by gphoto only
    [[ $THIS_IS_GPHOTO_CALLING == "yes" ]] || fatal "not calling from gphoto hook!"

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

  # gphoto downloaded a picture
	download)

    # should be called by gphoto only
    [[ $THIS_IS_GPHOTO_CALLING == "yes" ]] || fatal "not calling from gphoto hook!"

    # remove startscreen on first capture
    [[ -f $DIRECTORY/$STARTSCREEN ]] && rm "$DIRECTORY/$STARTSCREEN"
		
		# display new photo on top
		log "display new photo: $ARGUMENT"
		feh \
			--hide-pointer \
			--fullscreen \
			--zoom fill \
			--cycle-once \
			--slideshow-delay $SNAPSHOT_DELAY.5 \
			"$ARGUMENT" &

    # direct background feh to change photo shortly before current photo closes again
		sleep $SNAPSHOT_DELAY && kill -USR1 "$(cat photobooth.pid)" &

	;;

  # gphoto is stopping tethering
	stop)

    # should be called by gphoto only
    [[ $THIS_IS_GPHOTO_CALLING == "yes" ]] || fatal "not calling from gphoto hook!"

		log "killing all remaining feh processes"
		killall feh &

		log "remove pid file"
		rm photobooth.pid

	;;

  # error on unknown and empty actions
  '') fatal "no action given in \$ACTION" ;;
	*) fatal "unknown action: $ACTION" ;;

esac
