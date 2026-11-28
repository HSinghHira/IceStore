---
site: https://mediarium.app
source: https://github.com/rdborg/Mediarium
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: MUSIC_DIR
    group: Folders
    default: "/music"
    description: >-
      Your music library, like /DATA/Media/Music. Only used once you switch music on.
  - name: EBOOKS_DIR
    group: Folders
    default: "/ebooks"
    description: >-
      Your ebook library, like /DATA/Media/Ebooks. Only used once you switch ebooks on.
  - name: AUDIOBOOKS_DIR
    group: Folders
    default: "/audiobooks"
    description: >-
      Your audiobook library, like /DATA/Media/Audiobooks. Only used once you switch audiobooks on.
  - name: OTHER_DIR
    group: Folders
    default: "/other"
    description: >-
      A folder for other downloads, like /DATA/Media/Other.
  - name: UMASK
    group: Files
    default: ""
    description: >-
      Permissions for new files, like 002 so your group can change them. Blank keeps 022.
  - name: URL_BASE
    group: Network
    default: ""
    description: >-
      A path to serve Mediarium under behind a reverse proxy, like /mediarium.
  - name: TRUSTED_PROXIES
    group: Network
    default: "private"
    description: >-
      Which reverse proxies Mediarium trusts for the visitor's address. private trusts local network addresses.
  - name: ALLOWED_ORIGINS
    group: Network
    default: ""
    description: >-
      Other web addresses allowed to call the API from a browser, separated by commas.
  - name: MEDIARIUM_DISABLE_SSO
    group: Sign-in
    default: ""
    description: >-
      Set to 1 to turn off single sign-on and use only Mediarium's own passwords.
  - name: MEDIARIUM_DISABLE_STATS
    group: Privacy
    default: ""
    description: >-
      Set to 1 to never send the anonymous daily usage message (it is off until you say yes anyway).
  - name: MEDIARIUM_PAUSE_AUTOMATION
    group: Advanced
    default: ""
    description: >-
      Set to 1 to start with automatic searching and downloading paused, for fixing problems.
  - name: MEDIARIUM_SKIP_INSTALLED_UPDATE
    group: Advanced
    default: ""
    description: >-
      Set to 1 to ignore an update installed from the app and run the version in the image.
---

# Mediarium

Mediarium finds a movie or show on your Usenet and torrent indexers, downloads the best release, unpacks it, names it and puts it in your library for Plex, Jellyfin or Emby. It does the jobs of Radarr, Sonarr, Prowlarr, SABnzbd, a torrent client and Bazarr in one app: one container, one web page, one thing to update and back up.

## Features

- Movies and TV (anime, daily shows and specials included), plus music, ebooks and audiobooks if you switch them on
- Built-in Usenet and torrent downloaders, with repair and unpacking, and a built-in WireGuard VPN for torrents
- Quality profiles with upgrades and fallbacks, custom formats and Recyclarr support
- Subtitles matched to your exact file, with a timing fix
- Mediarium Books: a reader and audiobook player that remembers your place
- Family accounts with permissions and requests
- Works with phone apps like nzb360, LunaSea and Ruddarr
- Moves your setup over from Radarr, Sonarr, Prowlarr, SABnzbd and more, without changing them

## How to use

1. Open Mediarium and follow the setup wizard to make your admin account.
2. Add your indexers and Usenet servers, or bring them over from Radarr, Sonarr and Prowlarr.
3. Search for a movie or show and add it.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6882 and finish the setup wizard, which makes your admin account. Your ZimaOS storage is shared at the same path (/DATA): movies go to /DATA/Media/Movies, TV to /DATA/Media/TV and downloads to /DATA/Downloads, all on one disk so finished files move in at once. Change DOWNLOADS_DIR, MOVIES_DIR and TV_DIR in the app settings if your folders have other names. For torrents, set the Listen port to 6883 in Settings, Downloading, Usenet and torrents; IceStore publishes 6883 (TCP and UDP) for peers. Torrents still work without it, but you find fewer peers. Music, ebooks and audiobooks are off until you switch them on; point MUSIC_DIR, EBOOKS_DIR and AUDIOBOOKS_DIR at folders under /DATA first.
