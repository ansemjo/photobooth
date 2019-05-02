#!/usr/bin/env bash

# ------ LOGGING ------

# log a message to stdout and to system log, $2 = err --> emergency (red)
log() {
  msg="${1:?message required}"
  [[ $2 = "err" ]] && { prio=emerg; fmt='\033[1;31m%s\033[0m'; }
  printf "%s photobooth[%s]: ${fmt:-%s}\n" "$(date +%b\ %d\ %T)" "$$" "$msg"
  logger -t "photobooth" -p "${prio:-info}" "$msg"
}

# log an error and exit
err() { log "$1" err; exit 1; }

# redirect output stream to logfile
writelog() { while read line; do [[ -z $line ]] || log "$line" $1; done }

# ------ FUNCTIONS ------

# find the newest subdirectory somewhere or create one
newestdir() {
  dir=${1:?newestdir() requires a directory}; cd "${dir}";
  d=$(find "${dir}" -mindepth 1 -maxdepth 1 -type d -exec ls -d1t {} \+ | head -1)
  if [[ -z $d ]]; then
    d="${dir}/photobooth_$(date --utc +%F_%H%M%S)"
    mkdir -p "$d"
  fi
  echo "$d"
}

# check if we were called by a gphoto2 hook
gphoto_calling() {
  if [[ $THIS_IS_GPHOTO_CALLING != "yes" ]]; then
    err "action ${ACTION@Q} was not called from gphoto, abort!"
  fi
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

# ------ HOOKS ------

# bootstrap photobooth variables 
# and start thethering with gphoto2
bootstrap() {
  
  # source configuration files if available
  for cfg in /etc/photobooth.conf ~/.config/photobooth.conf; do
    if [[ -r $cfg ]]; then source "$cfg"; fi
  done

  # fallback to use the first display
  export DISPLAY="${DISPLAY:-:0}"

  # root folder to store albums under
  STORAGE="${STORAGE:-$HOME/Photobooth}"
  [[ -d $STORAGE ]] || err "directory ${STORAGE@Q} does not exist!"

  # choose subdirectory for photos
  export DIRECTORY=$(newestdir "$STORAGE")
  [[ -r $DIRECTORY ]] || err "directory ${DIRECTORY@Q} is not readable!"
  
  # runtime directory for temporary files
  export RUNTIME="${RUNTIME:-${XDG_RUNTIME_DIR:-${TMP:-/tmp}}}/photobooth"
  mkdir -p "$RUNTIME" || err "could not create runtime directory ${RUNTIME@Q}"

  # startscreen to display while no photos were taken
  export STARTSCREEN="${STARTSCREEN:-/usr/local/share/photobooth_start.png}"

  # slideshow and new photo delays
  export SLIDESHOW_TIME=${SLIDESHOW_TIME:-3}
  export NEXTPHOTO_TIME=${NEXTPHOTO_TIME:-5}
  
  # absolute path of this script
  script="$(realpath "$0")"
  
  # start thethered capture
  log "starting thethered capture with gphoto2"
  export THIS_IS_GPHOTO_CALLING=yes
  gphoto2 2>&1 1>/dev/null \
    --capture-tethered \
    --filename="$DIRECTORY/%Y%m%d-%H%M%S-%04n.%C" \
    --hook-script="$script" | writelog err

  teardown

}

hook_init() {

  # log directory that is used
  log "capture to directory: $DIRECTORY"

  # copy first frame if directory is empty
  if [[ -z "$(ls -A "$DIRECTORY")" ]]; then
    log "copy startup screen"
    cp -f "$STARTSCREEN" "$DIRECTORY/start"
  fi

  # start background slideshow
  slideshow

}

hook_download() {

  new=${1:?}
  log "new photo: $new"

  # remove startscreen on first capture
  [[ -f "$DIRECTORY/start" ]] && rm -f "$DIRECTORY/start"

  # display new photo
  singlephoto "$new"
  
  # kill slideshow after short delay, foreground singlephoto
  sleep 1
  killfeh "slideshow"
  
  # start new slideshow after some delay
  sleep "$NEXTPHOTO_TIME";
  slideshow;

  # kill single photo view, foreground slideshow
  sleep 1;
  killfeh "single";

}

hook_stop() {

  log "stoppping capture. killing slideshow .."
  killfeh "single" 2>/dev/null
  killfeh "slideshow" 2>/dev/null

}

teardown() {

  log "killing all remaining feh processes"
  killall feh 2>/dev/null

  log "remove stale pid files"
  rm -f "$RUNTIME/*.pid" 2>/dev/null

}

# ------ MAIN ------

case "$ACTION" in


  # udev hook when adding device
  add)
    # udev fires two add events .. silently exit on one
    [[ -n $DRIVER ]] && exit 0;
    # bootstrap photobooth with small delay to allow udev to finish
    log "new $ID_VENDOR_FROM_DATABASE camera attached";
    sleep 1 && bootstrap;
  ;;

  # gphoto is initialising tethered capture
  init) gphoto_calling && hook_init ;;
  start) : ;;

  # gphoto downloaded a picture
  download) gphoto_calling && hook_download "$ARGUMENT" ;;

  # gphoto is stopping tethering
  stop) gphoto_calling && hook_stop ;;

  # no action, probably started from commandline
  '')
    if pgrep gphoto2; then
      log "kill running photobooth instance ..."
      killall gphoto2
      sleep 2
    fi
    bootstrap
  ;;
  
  # log unknown actions
  *) log "unknown action: $ACTION" ;;

esac
