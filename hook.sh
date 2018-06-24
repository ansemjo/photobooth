#!/usr/bin/env bash
self=$(basename $0)

printf '%s %s\n' "$(date --utc +%FT%T%Z)" "EXECUTING HOOK"

case "$ACTION" in

	init)
		echo "$self: INIT"
	;;

	start)
		echo "$self: START"
	;;

	download)
		echo "$self: DOWNLOAD to $ARGUMENT"
		./slideshow.sh "$ARGUMENT" &
	;;

	stop)
		echo "$self: STOP"
	;;

	*)
		echo "$self: Unknown action: $ACTION"
		exit 1
	;;

esac

exit 0
