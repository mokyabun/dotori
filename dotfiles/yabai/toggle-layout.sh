#!/usr/bin/env bash
YABAI=/opt/homebrew/bin/yabai

layout=$($YABAI -m query --spaces --space | jq -r .type)
if [ "$layout" = "float" ]; then
  $YABAI -m space --layout bsp
  printf "yabai layout tiling" | nc -u -w0 127.0.0.1 9001
else
  $YABAI -m space --layout float
  printf "yabai layout floating" | nc -u -w0 127.0.0.1 9001
fi
