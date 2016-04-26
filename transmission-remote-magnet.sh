#!/usr/bin/env bash
#
# transmission-remote-magnet
# Add magnet urls to Transmission Remote
# Usage : transmission-remote-magnet.sh <ID_CATEGORY>
#
# Copyright (c) 2016 Denis Guriyanov <denis.guriyanov@gmail.com>
# Modified from https://gist.github.com/sbisbee/8215353


# Variables
################################################################################
export LANG=C
LC_ALL=C # fix charset

TR_CATEGORY="$1"

DIR_DWN="$HOME/Downloads/Torrents" # $HOME equal ~

TM_HOST='192.168.1.1'
TM_PORT='9091' # 9091 is default port
TM_USER=''
TM_PASS=''


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

TM_SESSID=$(curl "https://$TM_HOST:$TM_PORT/transmission/rpc" \
  --anyauth --user "$TM_USER":"$TM_PASS" \
  --silent '> /dev/null' \
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
  curl "https://$TM_HOST:$TM_PORT/transmission/rpc" \
    --anyauth --user "$TM_USER":"$TM_PASS" \
    --header "$TM_SESSID" \
    -d "{\"method\":\"torrent-add\",\"arguments\":{\"filename\":\"$link\"}}" \
    --silent > /dev/null

  printf "\rProgress : %d of $total_links" $i
  i=$((i+1))
done

echo "...complete!\n"


# FINISH
################################################################################
echo 'Enjoy...'

exit
