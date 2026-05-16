#!/usr/bin/env bash
AEROSPACE=/opt/homebrew/bin/aerospace

layout=$($AEROSPACE list-windows --focused --format '%{window-parent-container-layout}' | tr -d '[:space:]')
if [ "$layout" = "floating" ]; then
  $AEROSPACE layout tiling
  printf "aerospace layout tiling" | nc -u -w0 127.0.0.1 9001
else
  $AEROSPACE layout floating
  printf "aerospace layout floating" | nc -u -w0 127.0.0.1 9001
fi