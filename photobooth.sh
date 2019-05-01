#!/usr/bin/env bash
set -e

# ------ LOGGING ------

# log a message with a bolded timestamp in front, propagate to child shells
log() { printf '\033[%sm%s\033[0m %s\n' "${2:-1}" "$(date --utc "+%F %T")" "$1"; }
# log an error in bold red
err() { log "$1" "1;31"; }
# log an error and exit
fatal() { err "$1"; exit 1; }
# redirect output streams to logfile
writelog() { while read line; do log "$line" "1;34"; done }

# ------ FUNCTIONS ------

# find the newest subdirectory somewhere or create one
newestdir() {
  dir=${1:?}; name=${2:-Fotobox}; cd "${dir}";
  d=$(find "${dir}" -mindepth 1 -maxdepth 1 -type d -exec ls -d1t {} \+ | head -1)
  if [[ -z $d ]]; then
    d="${dir}/${name}_$(date --utc +%F_%H%M%S)"
    mkdir -p "$d"
  fi
  echo "$d"
}

# ------ MAIN SCRIPT ------

# check if we were called by a gphoto2 hook
gphoto_calling() {
  if [[ $THIS_IS_GPHOTO_CALLING != "yes" ]]; then
    fatal "Not calling from gphoto2 hook!"
  fi
}

# bootstrap photobooth and start thethering
bootstrap() {
  
  # full path of this script
  export THISSCRIPT=$(readlink -f "$0")

  # source configuration files
  for cfg in /etc/photobooth.conf ~/.config/photobooth.conf; do
    if [[ -r $cfg ]]; then source "$cfg"; fi
  done

  # fallback to use the first display
  export DISPLAY="${DISPLAY:-:0}"

  # root folder to store albums under
  STORAGE="${STORAGE:-$HOME/Photobooth}"
  [[ -d $STORAGE ]] || fatal "Directory '$STORAGE' does not exist!"

  # runtime directory for temporary files
  export RUNTIME="${RUNTIME:-$XDG_RUNTIME_DIR}"
  export RUNTIME="${RUNTIME:-/run/user/$EUID}/photobooth"
  mkdir -p "$RUNTIME"

  # startscreen and logging file
  export STARTSCREEN="/usr/local/share/photobooth_start.png"
  LOGFILE="/tmp/log.txt"

  # picture delays
  export SLIDESHOW_TIME=5
  export NEWPHOTO_TIME=6

  # choose subdirectory for photos
  export DIRECTORY=$(newestdir "$STORAGE")
  cd "$DIRECTORY"
  
  # start thethered capture
  export THIS_IS_GPHOTO_CALLING=yes
  gphoto2 2>/dev/null \
    --capture-tethered \
    --filename="$DIRECTORY/%Y%m%d-%H%M%S-%04n.%C" \
    --hook-script="$THISSCRIPT" | cat

  teardown;
  log "EXIT"
}

# ------ PICTURE DISPLAY -------

# start randomized slideshow in the background
slideshow() {
  feh --hide-pointer --fullscreen --zoom fill \
    --slideshow-delay "$SLIDESHOW_TIME" \
    --reload "$SLIDESHOW_TIME" \
    --randomize \
    "$DIRECTORY" &
  printf "$!" > "$RUNTIME/slideshow.pid"
  log "slideshow feh: $!"
}

# display a single photo for certain duration
singlephoto() {
  feh --hide-pointer --fullscreen --zoom fill \
    "${1:?}" &
  printf "$!" > "$RUNTIME/single.pid"
  log "new feh: $!"
}

# kill a feh instance $1 = {single|slideshow}
killfeh() {
  pid=$(< "$RUNTIME/${1:?}.pid")
  kill "$pid"
}

# ------ GPHOTO HOOKS ------

hook_init() {

  # log directory that is used
  log "directory: $DIRECTORY"

  # copy first frame if directory is empty
  if [[ -z "$(ls -A "$DIRECTORY")" ]]; then
    log "copy startup screen"
    cp -f "$STARTSCREEN" "$DIRECTORY/"
  fi

  # start background slideshow
  slideshow

}

hook_download() {

  new=$1
  log "new photo: $new"

  # remove startscreen on first capture
  startscreen="$DIRECTORY/$(basename "$STARTSCREEN")"
  if [[ -f $startscreen ]]; then rm -f "$startscreen"; fi

  # display new photo
  singlephoto "$new"
  
  # kill slideshow after some delay
  sleep 1
  killfeh "slideshow"
  
  # start new slideshow after some delay
  sleep "$NEWPHOTO_TIME";
  slideshow;

  # kill single photo view
  sleep 1;
  killfeh "single";

}

teardown() {

  log "killing all remaining feh processes"
  killall feh 2>/dev/null

  log "remove pid files"
  rm -f "$RUNTIME/*.pid" 2>/dev/null

}

case "$ACTION" in

  # udev hook when adding device
  add)
    # udev fires two add events .. silently exit on one
    [[ -n $DRIVER ]] && exit 0;
    # bootstrap photobooth with small delay
    log "new $ID_VENDOR_FROM_DATABASE camera attached";
    sleep 1 && bootstrap;
  ;;

  # gphoto is initialising tethered capture
  init) gphoto_calling && hook_init ;;
  start) : ;;

  # gphoto downloaded a picture
  download) gphoto_calling && hook_download "$ARGUMENT" ;;

  # gphoto is stopping tethering
  stop) gphoto_calling && teardown ;;

  # no action, probably started from commandline
  '') bootstrap ;;
  
  # log unknown actions
  *) log "unknown action: $ACTION" ;;

esac
