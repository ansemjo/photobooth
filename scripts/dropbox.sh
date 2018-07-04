#!/bin/bash

sleeep() {
  i=$1; t=${2:-waiting}
  while [[ $i -gt 0 ]]; do
    printf '\r%s %02d seconds ...' "$t" "$i"
    ((i--))
    sleep 1
  done
  printf '\r'
}

drop() {

  STATUS=$(dropbox start)

  if [[ $STATUS =~ "daemon is not installed" ]]; then
    echo "DROPBOX DAEMON IS NOT INSTALLED YET."
    dropbox start -i
    return 2
  fi

  if [[ $STATUS =~ "link this computer" ]]; then
    echo "FOLLOW THIS QR CODE TO LINK THIS COMPUTER TO YOUR DROPBOX"
    echo "$STATUS" | grep '^https://' | qrencode -t ANSI
    sleeep 10 'recheck in'
    return 1
  fi

  if [[ $STATUS =~ "Dropbox is already running" ]]; then
    echo "$STATUS"
    sleeep 5 'exit in'
    exit 0
  fi

  sleeep 5 'unknown status ... retry in'
  return 1

}

echo "Dropbox launcher .."
sleeep 3

dropbox start

while ! drop; do
  sleeep 2
  clear
done
