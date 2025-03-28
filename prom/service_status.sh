#!/bin/bash

if [ -z $1 ];then
  echo "error:No server"
  echo "Usage: script + server"
  exit
fi
if systemctl is-active $1 &>/dev/null; then
  echo "$1 is started"
else
  echo "$1 is not started"
fi

if systemctl is-enabled $1 &>/dev/null; then
  echo "$1 Is the boot auto option"
else
  echo "$1 Not start auto option"
fi
