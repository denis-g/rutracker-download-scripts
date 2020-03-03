#!/usr/bin/env bash
export LC_ALL=C

# rutracker-catalog-torrent
# Download .torrent-files from custom category ID
# Usage : sh rutracker-catalog-torrent.sh <ID_CATEGORY>
#
# Copyright (c) 2018 Denis Guriyanov <denisguriyanov@gmail.com>


# Variables
################################################################################
TR_USER=''
TR_PASSWORD=''

TR_HOST='rutracker.org'
TR_PROTOCOL='https'
TR_CATEGORY="$1"
TR_TIMEOUT='1' # in sec

DIR_DWN="$HOME/Downloads/Torrents" # $HOME equal ~
DIR_DWN_CAT="$DIR_DWN/$TR_CATEGORY"
DIR_TMP='/tmp/rds'
DIR_TMP_CAT="$DIR_TMP/$TR_CATEGORY"

SC_COOKIE="$DIR_TMP/$TR_HOST-$TR_USER.cookie"
SC_UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:44.0) Gecko/20100101 Firefox/44.0'


# BEGIN
################################################################################
if [ -z $TR_CATEGORY ]; then
  echo 'Please, enter category ID.'
  echo 'Example: rutracker-catalog-torrent.sh <ID_CATEGORY>'
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
if [ ! -d $DIR_DWN_CAT ]; then
  mkdir -p "$DIR_DWN_CAT"
fi


# Get cookie, login and authentication
################################################################################
echo 'User authentication...'

if [ -w $SC_COOKIE ]; then
  auth_page=$(curl "$TR_PROTOCOL://$TR_HOST/index.php" \
    -b "$SC_COOKIE" \
    -c "$SC_COOKIE" \
    -A "$SC_UA" \
    --show-error \
    -L \
    -s
  )
  username=$(echo "$auth_page" | egrep -o "$TR_USER")
  # DEBUG
  echo "$auth_page" > "$DIR_TMP"/page_auth.html
fi

sleep 1

if [ -z $username ]; then
  auth_path="$TR_PROTOCOL://$TR_HOST/forum/login.php"
  if [ -w $SC_COOKIE ]; then
    cookie_data=$(cat "$SC_COOKIE")
    curl "$auth_path" \
      --trace-ascii - \
      -b "$SC_COOKIE" \
      -c "$SC_COOKIE" \
      -A "$SC_UA" \
      -d "login_username=$TR_USER" \
      -d "login_password=$TR_PASSWORD" \
      --data-binary 'login=%C2%F5%EE%E4' \
      --show-error \
      -L \
      -s
  else
    curl "$auth_path" \
      --trace-ascii - \
      -c "$SC_COOKIE" \
      -A "$SC_UA" \
      -d "login_username=$TR_USER" \
      -d "login_password=$TR_PASSWORD" \
      --data-binary 'login=%C2%F5%EE%E4' \
      --show-error \
      -L \
      -s
  fi
fi

echo "...complete!\n"

sleep 1


# Get total pages in category
################################################################################
echo 'Get total pages in category...'

category_page=$(curl "$TR_PROTOCOL://$TR_HOST/forum/viewforum.php?f=$TR_CATEGORY&start=0" \
  -b "$SC_COOKIE" \
  -c "$SC_COOKIE" \
  -A "$SC_UA" \
  -d 'o=10' \
  -d 's=2' \
  --show-error \
  -L \
  -s
)

# find latest pager link
# <a class="pg" href="viewforum.php?f=###&amp;start=###">###</a>&nbsp;&nbsp;
total_pages=$(echo "$category_page" \
  | sed -En 's/.*<a class=\"pg\" href=\".*\">([0-9]*)<\/a>&nbsp;&nbsp;.*/\1/p' \
  | head -1
)


echo "...complete!\n"

sleep 1


# Download category pages
################################################################################
echo 'Download category pages...'

for page in $(seq 1 $total_pages); do
  page_link=$((page * 50 - 50)) # 50 items per page - 0..50..100
  category_pages=$(curl "$TR_PROTOCOL://$TR_HOST/forum/viewforum.php?f=$TR_CATEGORY&start=$page_link" \
    -b "$SC_COOKIE" \
    -c "$SC_COOKIE" \
    -A "$SC_UA" \
    -d 'o=10' \
    -d 's=2' \
    --show-error \
    -L \
    -s
  )
  echo "$category_pages" > "$DIR_TMP_CAT/page_$page.html"
  printf "\rCurrent page : %d of $total_pages" $page
done

echo "\n...complete!\n"

sleep 1


# Get torrent id's
################################################################################
echo "Get torrent id's..."

id_list="$DIR_TMP_CAT/ids_list.txt"
touch "$id_list"

for page in $(seq 1 $total_pages); do
  category_page="$DIR_TMP_CAT/page_$page.html"
  # find torrent topic link
  # <a id="tt-###" href="viewtopic.php?t=###">
  ids=$(cat "$category_page" \
    | sed -En 's/.*<a.*id=\"tt-[0-9]*\".*href=\"viewtopic\.php\?t=([0-9]*)\".*>.*/\1/p'
  )
  echo "$ids" >> "$id_list"
done

echo "...complete!\n"

sleep 1


# Download torrent files
################################################################################
echo 'Download torrent files...'

total_id=$(cat "$id_list" \
  | wc -l \
  | sed 's/ //g'
)
i=1

for id in $(cat "$id_list"); do
  curl \
    --cookie "bb_dl=$id" \
    -b "$SC_COOKIE" \
    -c "$SC_COOKIE" \
    -A "$SC_UA" \
    -e "$TR_PROTOCOL://$TR_HOST/forum/viewtopic.php?t=$id" "$TR_PROTOCOL://$TR_HOST/forum/dl.php?t=$id" \
    -o "$DIR_DWN_CAT/[rutracker.org].t$id.torrent" \
    --show-error \
    -L \
    -s
  printf "\rDownloaded files : %d of $total_id" $i

  i=$((i+1))
  sleep "$TR_TIMEOUT" # fix massive request
done

echo "\n...complete!\n"

sleep 1


# FINISH
################################################################################
echo 'Enjoy...'

exit
