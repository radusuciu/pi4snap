#!/usr/bin/env bash

sed -i "s/<SPOTIFY_USERNAME>/${SPOTIFY_USERNAME}/" /etc/snapserver.conf
sed -i "s/<SPOTIFY_PASSOWRD>/${SPOTIFY_PASSOWRD}/" /etc/snapserver.conf

exec snapserver
