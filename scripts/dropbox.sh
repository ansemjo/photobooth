#!/bin/bash

drop() {

  STATUS=$(dropbox start)

  if [[ $STATUS =~ "daemon is not installed" ]]; then
    echo "DROPBOX DAEMON IS NOT INSTALLED YET."
    echo y | DISPLAY= dropbox start -i
    return 2
  fi

  if [[ $STATUS =~ "link this computer" ]]; then
    echo "FOLLOW THIS QR CODE TO LINK THIS COMPUTER TO YOUR DROPBOX"
    echo "$STATUS" | grep '^https://' | qrencode -t ANSI
    return 0
  fi

}

while ! drop; do
  sleep 2
done
