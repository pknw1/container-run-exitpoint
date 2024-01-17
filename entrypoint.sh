#!/bin/bash

function ensure_started_container {
  exists=`docker ps -q | grep $1`
  if [ "$?" = "0" ] ; then
    echo "[docker-exec] skipping docker start, already started"
  else
    output=`docker start "$1"`
    echo "[docker start] $output"
  fi
  running=1
}

function setup_signals {
  cid="$1"; shift
  handler="$1"; shift
  for sig; do
    trap "$handler '$cid' '$sig'" "$sig"
  done
}

function handle_signal {
  echo "[docker-exec] received $2"
  case "$2" in
    SIGINT)
      output=`docker stop -t 5 "$1"`
      echo "[docker stop] $output"
      running=0
      ;;
    SIGTERM)
      output=`docker stop -t 5 "$1"`
      echo "[docker stop] $output"
      running=0
      ;;
    SIGHUP)
      output=`docker restart -t 5 "$1"`
      echo "[docker restart] $output"

      # restart logging
      docker attach "$1" &
      kill "$logger_pid" 2> /dev/null
      logger_pid="$!"
      ;;
  esac
}

running=0

setup_signals "$1" "handle_signal" SIGINT SIGTERM SIGHUP

ensure_started_container "$1"

docker attach "$1" &
logger_pid="$!"

while true; do
  if [ "$running" = "1" ]; then
    sleep 1
  else
    break
  fi
done

exit_code=`docker wait "$1"`
exit "$exit_code"
