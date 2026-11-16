---
site: https://filebrowserquantum.com
source: https://github.com/gtsteffaniak/filebrowser
screenshots: [Files]
variables:
  - name: FILEBROWSER_OIDC_CLIENT_ID
    group: Sign in with OIDC
    default: ""
    description: >-
      The client ID from your OIDC provider. Turn OIDC on and set its issuer in config.yaml (auth, methods, oidc).
  - name: FILEBROWSER_OIDC_CLIENT_SECRET
    group: Sign in with OIDC
    default: ""
    description: >-
      The client secret from your OIDC provider.
  - name: FILEBROWSER_JWT_TOKEN_SECRET
    group: Security
    default: ""
    description: >-
      Your own secret for signing logins. Leave it out to let FileBrowser manage one.
  - name: FILEBROWSER_TOTP_SECRET
    group: Security
    default: ""
    description: >-
      A secret for two-factor codes. Leave it out to let FileBrowser manage one.
  - name: FILEBROWSER_ONLYOFFICE_SECRET
    group: Office
    default: ""
    description: >-
      The JWT secret of your OnlyOffice Docs server, for editing Office files. Set its address in config.yaml (integrations, office).
---

# FileBrowser Quantum

FileBrowser Quantum is a web file manager for your files. Browse, upload, move and share files from any browser, find anything in a second with its search index, and preview photos, videos and documents without downloading them.

## Features

- Very fast search across all your files
- Previews and thumbnails for images, videos, PDFs and Office files
- Share links with expiry and passwords
- Users with their own folders and permissions
- Sign-in with a password, OIDC or a proxy, with two-factor codes
- Upload large files and whole folders

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6738` and sign in as admin. The password is in the app's logs, in the box marked CREDENTIALS.
2. Browse your files under files.
3. Right-click a file or folder to share, move or rename it.

## Before you install

Leave `FILEBROWSER_ADMIN_PASSWORD` blank and the app makes a random admin password on first start. It is printed in the app's logs, in the box marked CREDENTIALS, and saved in `/DATA/AppData/filebrowser-quantum/data/password.txt`. The app sees all of `/DATA` and runs as root so it can change those files; to share less, point the `/srv` folder at a smaller one, like `/DATA/Media`. A starter `config.yaml` is made in the app folder on first start; edit it with the Files app for more sources, OIDC, OnlyOffice and the rest (it is never overwritten). The first start indexes your files, which can take a few minutes on big disks.
