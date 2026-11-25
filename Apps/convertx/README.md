---
source: https://github.com/C4illin/ConvertX
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: JWT_SECRET
    group: Security
    default: ""
    description: >-
      A long random text that signs sign-ins. Left out, a new one is
      made on every start and everyone signs in again after a restart.
  - name: AUTO_DELETE_EVERY_N_HOURS
    group: Files
    default: "24"
    description: >-
      Delete uploaded and converted files after this many hours (0 keeps
      them).
  - name: ALLOW_UNAUTHENTICATED
    group: Security
    default: "false"
    description: >-
      Set to true to use ConvertX without an account.
  - name: WEBROOT
    group: Server
    default: ""
    description: >-
      Serve ConvertX under a sub-path, like /convert.
  - name: FFMPEG_ARGS
    group: Converters
    default: ""
    description: >-
      Extra FFmpeg options, like -hwaccel vaapi.
  - name: HIDE_HISTORY
    group: Server
    default: "false"
    description: >-
      Set to true to hide the history page.
  - name: LANGUAGE
    group: Server
    default: "en"
    description: >-
      The language for dates, like en or de.
---

# ConvertX

ConvertX converts images, documents, audio, video, e-books and 3D files between over a thousand formats, using FFmpeg, LibreOffice, Pandoc, ImageMagick, Calibre and more inside one app. Upload, pick a format, download.

## Features

- Over a thousand formats through FFmpeg, ImageMagick, LibreOffice, Pandoc, Calibre, Inkscape and more
- Convert many files at once
- Accounts with password protection
- Old files cleaned up after a set time

## How to use

1. Open ConvertX right away and make your account.
2. Drop files, pick the target format and press Convert.
3. Download the results.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6838 and make your account; only the first account can sign up unless you set ACCOUNT_REGISTRATION=true. HTTP_ALLOWED=true is needed to sign in over plain http; set JWT_SECRET to a long random text so you stay signed in after restarts. Files are deleted after 24 hours by default.
