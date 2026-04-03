#!/bin/bash

set -e

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

while true; do
  log "Starting media sync"

  mkdir -p /srv/media/staged-area/movies
  mkdir -p /srv/media/staged-area/tvshows
  mv /srv/media/movies/* /srv/media/staged-area/movies/ || true
  mv /srv/media/tvshows/* /srv/media/staged-area/tvshows/ || true

  mkdir -p /srv/media/PLEX26/movies
  mkdir -p /srv/media/PLEX26/tvshows
  mkdir -p /srv/media/NAS/movies
  mkdir -p /srv/media/NAS/tvshows
  cp -r /srv/media/staged-area/movies/. /srv/media/PLEX26/movies/
  cp -r /srv/media/staged-area/tvshows/. /srv/media/PLEX26/tvshows/
  cp -r /srv/media/staged-area/movies/. /srv/media/NAS/movies/
  cp -r /srv/media/staged-area/tvshows/. /srv/media/NAS/tvshows/

  rm -rf /srv/media/staged-area
  log "Media sync complete"

  sleep 15
done
