---
site: https://sftpgo.com
source: https://github.com/drakkan/sftpgo
services:
  - { name: Web admin, path: /web/admin, icon: server }
  - { name: Web client, path: /web/client, icon: globe }
screenshots: [Web admin, Web client]
variables:
  - name: SFTPGO_DATA_PROVIDER__CREATE_DEFAULT_ADMIN
    group: First admin
    default: "false"
    description: >-
      Set to true to make the first admin from the two settings below instead of in the browser.
  - name: SFTPGO_DEFAULT_ADMIN_USERNAME
    group: First admin
    default: ""
    description: >-
      The first admin's user name.
  - name: SFTPGO_DEFAULT_ADMIN_PASSWORD
    group: First admin
    default: ""
    description: >-
      The first admin's password.
  - name: SFTPGO_COMMON__DEFENDER__ENABLED
    group: Security
    default: "false"
    description: >-
      Set to true to block addresses that keep guessing passwords.
  - name: SFTPGO_HTTPD__BINDINGS__0__ENABLE_WEB_CLIENT
    group: Web
    default: "true"
    description: >-
      Set to false to turn off the web client for users.
  - name: SFTPGO_SMTP__HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, for password resets and event emails.
  - name: SFTPGO_SMTP__PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      The mail server's port.
  - name: SFTPGO_SMTP__USER
    group: Email (SMTP)
    default: ""
    description: >-
      The mail server user name.
  - name: SFTPGO_SMTP__PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The mail server password.
  - name: SFTPGO_SMTP__FROM
    group: Email (SMTP)
    default: ""
    description: >-
      The sender, like SFTPGo <sftpgo@example.com>.
  - name: SFTPGO_SMTP__ENCRYPTION
    group: Email (SMTP)
    default: "0"
    description: >-
      0 for none, 1 for TLS, 2 for STARTTLS.
---

# SFTPGo

SFTPGo is a file server you manage from the browser. Make users, give each a home folder on your server or in the cloud, and let them connect with any SFTP app, or upload and share files in the web client.

## Features

- SFTP, and optional FTP/S and WebDAV
- Users and groups with their own folders, quotas and limits
- Folders on your disks, or on S3, Google Cloud, Azure or another SFTP server
- A web client for users, with share links
- Two-factor login, an IP block list and protection against password guessing
- Event rules: run actions or send emails when files change

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6739/web/admin` right away and make the admin account.
2. Go to Users and add a user with a password. Set their home folder, like `/DATA/Media`, or leave it for a new folder.
3. Connect with an SFTP app (FileZilla, WinSCP) to your ZimaOS IP on port 6740, or open `http://[ZIMAOS-IP-ADDRESS]:6739/web/client`.

## Before you install

Nothing needs to be set first. Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6739/web/admin` and make the admin account: the first person to open that page does it. Or set the first admin in the Variables tab before you start. SFTP is on port 6740. The app can see all of `/DATA`, so you can give users existing folders, and it runs as root so it can write to them. Email, password-guessing protection and the other settings are in the Variables tab; add them in the app settings.
