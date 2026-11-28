---
site: https://watcharr.app
source: https://github.com/sbondCo/Watcharr
screenshots: [Overview, Watch list, Movie details, Discover]
services:
  - { name: Web App, path: /, icon: globe }
---

# Watcharr

Watcharr is a watched list for everything you watch and play. Add movies, TV shows, anime and games, rate them, mark episodes as watched and see what your friends think.

## Features

- Movies, shows, anime and (with an IGDB key) games
- Ratings, thoughts and episode-by-episode progress
- Follow friends and see their lists
- Import from Trakt, Letterboxd, MyAnimeList, IMDb and more
- Sign in with Jellyfin or Plex, and sync your watched items

## How to use

1. Open Watcharr and create an account. The first account is the admin.
2. Search for a movie or show and add it to your list.
3. Rate it and mark what you've watched.

## Before you install

Watcharr has no default login: the first account made at http://[ZIMAOS-IP-ADDRESS]:6898 becomes the admin, so make yours right after installing, then turn off sign-up in the server settings. Everything else (sign-up, Jellyfin or Plex sign-in, Sonarr and Radarr, the IGDB key for games) is set on Watcharr's server settings page, not with variables. The sign-in key is made on first start and kept in the data folder.
