#!/usr/bin/env bash
#
# rutracker-catalog-magnet
# Create list with magnet urls from custom category ID
# Usage : rutracker-catalog-magnet.sh <ID_CATEGORY>
#
# Copyright (c) 2016 Denis Guriyanov <denis.guriyanov@gmail.com>


# Variables
################################################################################
export LANG=C

TR_HOST='rutracker.org'
TR_CATEGORY="$1"

DIR_DWN="$HOME/Downloads/Torrents" # $HOME equal ~
DIR_TMP='/tmp/rds'
DIR_TMP_CAT="$DIR_TMP/category_$TR_CATEGORY"

SC_UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:44.0) Gecko/20100101 Firefox/44.0'


# BEGIN
################################################################################
if [ -z $TR_CATEGORY ]; then
  echo 'Please, enter category ID.'
  echo 'Example: rutracker-catalog-magnet.sh <ID_CATEGORY>'
  exit
fi

echo "Let's Go!\n"


# Check and create directories
################################################################################
if [ ! -d $DIR_TMP ]; then
  mkdir "$DIR_TMP"
fi
if [ ! -d $DIR_TMP_CAT ]; then
  mkdir -p "$DIR_TMP_CAT"
else
  # remove old files
  rm -rf "$DIR_TMP_CAT"/*
fi

if [ ! -d $DIR_DWN ]; then
  mkdir "$DIR_DWN"
fi


# Total pages
################################################################################
echo 'Get total pages in category...'

category_page=$(curl "http://$TR_HOST/forum/viewforum.php?f=$TR_CATEGORY&start=0" \
  -A "$SC_UA" \
  --silent '> /dev/null'
)

# find latest pager link
# <a class="pg" href="viewforum.php?f=###&amp;start=###">###</a>&nbsp;&nbsp;
total_pages=$(echo $category_page \
  | sed -En 's/.*<a class=\"pg\" href=\".*\">([0-9]*)<\/a>&nbsp;&nbsp;.*/\1/p' \
  | head -1
)

echo "...complete!\n"

sleep 1


# Category Page
################################################################################
echo 'Download category pages...'

for page in $(seq 1 $total_pages); do
  page_link=$((page * 50 - 50)) # 50 items per page, ex. 0..50..100
  category_pages=$(curl "http://$TR_HOST/forum/viewforum.php?f=$TR_CATEGORY&start=$page_link" \
    -A "$SC_UA" \
    --silent '> /dev/null'
  )
  echo "$category_pages" > "$DIR_TMP_CAT/category_page_$page.html"
  printf "\rProgress : %d of $total_pages" $page
done

echo "\n...complete!\n"

sleep 1


# Torrent ID
################################################################################
echo "Get torrent IDs..."

id_list="$DIR_TMP_CAT/ids_list.txt"
touch "$id_list"

for page in $(seq 1 $total_pages); do
  category_page="$DIR_TMP_CAT/category_page_$page.html"
  # find torrent topic link
  # <a id="tt-###" href="viewtopic.php?t=###">
  ids=$(cat $category_page \
    | sed -En 's/.*<a.*href=\"viewtopic\.php\?t=([0-9]*)\".*>.*/\1/p'
  )
  echo "$ids" >> "$id_list"
done

echo "...complete!\n"

sleep 1


# Magnet URL
################################################################################
echo 'Get magnet URLs...'

total_ids=$(cat $id_list \
  | wc -l \
  | sed 's/ //g'
)
i=1

magnet_list="$DIR_DWN/$TR_CATEGORY.txt"
if [ -f $magnet_link ]; then
  rm -f "$magnet_list"
else
  touch "$magnet_list"
fi

for id in $(cat $id_list); do
  torrent_page=$(curl "http://$TR_HOST/forum/viewtopic.php?t=$id" \
    -A "$SC_UA" \
    --silent '> /dev/null' \
  )
  # find magnet link on page
  # <a href="magnet:###">
  magnet_link=$(echo $torrent_page \
    | sed -En 's/.*<a.*href=\"(magnet:[^"]*)\".*>.*/\1/p'
  )
  if [ $magnet_link ]; then
    echo "$magnet_link" >> "$magnet_list"
  fi

  printf "\rProgress : %d of $total_ids" $i
  i=$((i+1))
done

echo "\n...complete!\n"


# FINISH
################################################################################
total_links=$(cat $magnet_list \
  | wc -l \
  | sed 's/ //g'
)

echo "Total URLs : $total_links\n"
echo 'Enjoy...'

exit
