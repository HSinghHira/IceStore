---
source: https://github.com/alexta69/metube
screenshots: [Downloading]
variables:
  - name: MAX_CONCURRENT_DOWNLOADS
    group: Downloads
    default: "3"
    description: >-
      How many downloads run at once. The rest wait their turn.
  - name: DEFAULT_OPTION_PLAYLIST_ITEM_LIMIT
    group: Downloads
    default: "0"
    description: >-
      How many items of a playlist or channel to download by default. 0 means all.
  - name: CLEAR_COMPLETED_AFTER
    group: Downloads
    default: "0"
    description: >-
      Seconds before finished downloads leave the Completed list. 0 keeps them.
  - name: DELETE_FILE_ON_TRASHCAN
    group: Downloads
    default: "false"
    description: >-
      Set to true to also delete the file when you remove it from Completed, or ask to be asked each time.
  - name: SUBSCRIPTION_DEFAULT_CHECK_INTERVAL
    group: Downloads
    default: "60"
    description: >-
      Minutes between checks of a channel or playlist you subscribed to.
  - name: AUDIO_DOWNLOAD_DIR
    group: Folders
    default: "/downloads"
    description: >-
      Where audio-only downloads go, like /downloads/audio, to keep them apart from videos.
  - name: CUSTOM_DIRS
    group: Folders
    default: "true"
    description: >-
      Set to false to hide the Download Folder field.
  - name: DEFAULT_FOLDER
    group: Folders
    default: ""
    description: >-
      The folder the Download Folder field starts with, inside the downloads folder.
  - name: OUTPUT_TEMPLATE
    group: File names
    default: "%(title)s.%(ext)s"
    description: >-
      The file name for downloads, in yt-dlp's output template format.
  - name: OUTPUT_TEMPLATE_PLAYLIST
    group: File names
    default: "%(playlist_title)s/%(title)s.%(ext)s"
    description: >-
      The file name for items from a playlist.
  - name: OUTPUT_TEMPLATE_CHANNEL
    group: File names
    default: "%(channel)s/%(title)s.%(ext)s"
    description: >-
      The file name for items from a channel.
  - name: YTDL_OPTIONS
    group: yt-dlp
    default: "{}"
    description: >-
      yt-dlp options for every download, as JSON, like {"writesubtitles": true, "subtitleslangs": ["en"]}.
  - name: YTDL_OPTIONS_PRESETS
    group: yt-dlp
    default: "{}"
    description: >-
      Named sets of yt-dlp options, as JSON, that you can pick for each download.
  - name: YTDL_NIGHTLY_UPDATE_TIME
    group: yt-dlp
    default: ""
    description: >-
      Use the nightly yt-dlp and update it every day at this time, like 04:00. Helps when a site changes.
  - name: DEFAULT_THEME
    group: Web page
    default: "auto"
    description: >-
      light, dark, or auto to follow your device.
  - name: CORS_ALLOWED_ORIGINS
    group: Web page
    default: ""
    description: >-
      Other sites allowed to send links to MeTube, comma separated, for browser extensions and bookmarklets.
  - name: UMASK
    group: Files
    default: "022"
    description: >-
      The umask for files MeTube makes. 002 lets your group write them too.
  - name: LOGLEVEL
    group: Logs
    default: "INFO"
    description: >-
      DEBUG, INFO, WARNING, ERROR, CRITICAL or NONE.
---

# MeTube

MeTube is a web page for yt-dlp. Paste a link from YouTube or one of hundreds of other sites, and it downloads the video, the audio, or a whole playlist or channel to your server.

## Features

- Videos, audio only, subtitles and thumbnails
- Single videos, whole playlists or entire channels
- Subscriptions that download new uploads by themselves
- Pick the quality, format and folder for each download
- Several downloads at once, with a queue
- Browser extensions and bookmarklets to send links from any page

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6731` in your browser.
2. Paste a video, playlist or channel link and press Download.
3. Find the files in the Files app, under Downloads, metube.

## Before you install

Nothing needs to be set first, and it starts in a few seconds. Downloads go to `/DATA/Downloads/metube`; the queue, history and subscriptions are kept in the app folder. MeTube has no login, so keep port 6731 on your home network. File names, folders, yt-dlp options and the other settings are in the Variables tab; add them in the app settings.
