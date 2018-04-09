#!/usr/bin/env bash
export LC_ALL=C

# transmission-remote-magnet
# Add magnet urls to Transmission Remote
# Usage : sh transmission-remote-magnet.sh <ID_CATEGORY>
#
# Copyright (c) 2018 Denis Guriyanov <denisguriyanov@gmail.com>
# Modified from https://gist.github.com/sbisbee/8215353


# Variables
################################################################################
TM_HOST=''
TM_PORT='9091' # 9091 is default port
TM_USER=''
TM_PASS=''

TR_CATEGORY="$1"
TR_TIMEOUT='0.30'

DIR_DWN="$HOME/Downloads/Torrents" # $HOME equal ~


# BEGIN
################################################################################
if [ -z $TR_CATEGORY ]; then
  echo 'Please, enter category ID.'
  echo 'Example: transmission-remote-magnet.sh <ID_CATEGORY>'
  exit
fi

echo "Let's Go!\n"


# Connect
################################################################################
echo 'Connecting to Transmission Remote...'

TM_SESSID=$(curl "http://$TM_HOST:$TM_PORT/transmission/rpc" \
  --anyauth --user "$TM_USER":"$TM_PASS" \
  --show-error \
  -L \
  -s \
  | sed 's/.*<code>//g;s/<\/code>.*//g'
)

echo "...complete!\n"


# Added
################################################################################
echo 'Added links...'

magnet_list="$DIR_DWN/$TR_CATEGORY.txt"
total_links=$(cat $magnet_list \
  | wc -l \
  | sed 's/ //g'
)
i=1

for link in $(cat $magnet_list); do
  curl "http://$TM_HOST:$TM_PORT/transmission/rpc" \
    --anyauth --user "$TM_USER":"$TM_PASS" \
    --header "$TM_SESSID" \
    -d "{\"method\":\"torrent-add\",\"arguments\":{\"filename\":\"$link\"}}" \
    --show-error \
    -L \
    -o /dev/null \
    -s

  printf "\rProgress : %d of $total_links" $i
  i=$((i+1))

  sleep "$TR_TIMEOUT" # fix massive request
done

echo "\n...complete!\n"


# FINISH
################################################################################
echo 'Enjoy...'

exit
