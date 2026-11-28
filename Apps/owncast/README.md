---
site: https://owncast.online
source: https://github.com/owncast/owncast
screenshots: [Stream page, Follow, Notifications]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: OWNCAST_ADMIN_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The admin password. Made on first start and kept in the data
      folder when left out; it is set again on every start.
  - name: OWNCAST_STREAM_KEY
    group: Streaming
    default: ""
    description: >-
      The stream key OBS uses. Made on first start and kept in the data
      folder when left out.
---

# Owncast

Owncast is a live streaming server you run yourself. Stream from OBS or any RTMP app, and your viewers watch on your own page with chat, emoji and followers, without ads or a platform in between.

## Features

- Works with OBS, Streamlabs, Larix and any RTMP software
- Built-in chat with moderation, emoji and custom styles
- Several video qualities with transcoding, or passthrough to save CPU
- Fediverse followers and notifications to Discord and more
- Your own page, colours, logo and offline message

## How to use

1. Open Owncast's admin page at /admin. The user name is admin; the password is in the CREDENTIALS box in the app's logs.
2. In OBS, set the server to rtmp://[ZIMAOS-IP-ADDRESS]:6861/live and the stream key from the same box.
3. Start streaming and share the page address.

## Before you install

The admin page is at http://[ZIMAOS-IP-ADDRESS]:6860/admin with the user admin. Its password and a stream key are made on first start, shown in the app's logs in the box marked CREDENTIALS, and set again on every start (so change them with OWNCAST_ADMIN_PASSWORD and OWNCAST_STREAM_KEY, not in the admin page). Delete the old default stream key abc123 under Server Setup. Stream from OBS to rtmp://[ZIMAOS-IP-ADDRESS]:6861/live. Transcoding uses a lot of CPU; try passthrough in Video Configuration on a small box. Viewers outside your home need the ports forwarded or a reverse proxy.
