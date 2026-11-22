---
site: https://jellyfin.org/
services:
  - { name: Jellyfin, path: /, icon: monitor }
screenshots: [Home, Library, Details, Playback]
variables:
  - name: JELLYFIN_PublishedServerUrl
    group: Server
    default: ""
    description: >-
      The address Jellyfin tells apps to use when they find it on your
      network, like http://[ZIMAOS-IP-ADDRESS]:6798.
---

# Jellyfin

Jellyfin is a free media server. Point it at your movies, TV shows, music and photos, and it fetches posters and details, then streams them to your TV, phone, browser or game console. No account with anyone else, no tracking, no paid tier.

## Features

- Movies, shows, music, books and photos in tidy libraries
- Apps for Android, iOS, Android TV, Fire TV, Roku, Kodi and more
- Converts video on the fly when a device can't play the file
- Users with parental controls and their own watch history
- Live TV and DVR with a tuner
- Plugins, subtitles and SyncPlay to watch together

## How to use

1. Open Jellyfin from your dashboard.
2. Follow the setup wizard and make your admin user.
3. Add a library and pick a folder under /DATA, like /DATA/Media/Movies.
4. Wait for the scan, then press play.

## Before you install

Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6798` and follow the setup wizard, which makes your admin user; until you do, anyone on your network can. Your ZimaOS storage is shared at `/DATA`, so libraries can point at folders like `/DATA/Media/Movies`. In the Jellyfin apps, use `http://[ZIMAOS-IP-ADDRESS]:6798` as the server. Hardware transcoding is not set up (the GPU is not passed in), so video that needs converting uses the CPU. Settings and the library database are in `/DATA/AppData/jellyfin/config`. It is ready in about a minute.
