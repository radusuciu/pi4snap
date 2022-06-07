#!/usr/bin/env bash

sed "s/<SPOTIFY_USERNAME>/${SPOTIFY_USERNAME}/" /etc/snapserver.conf.template | sed "s/<SPOTIFY_PASSWORD>/${SPOTIFY_PASSWORD}/" > /etc/snapserver.conf
exec snapserver
