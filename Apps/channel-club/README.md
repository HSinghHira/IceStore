---
services:
  - { name: Player, path: /, icon: monitor }
  - { name: Setup Wizard, path: /setup, icon: server }
screenshots: [Player and channel guide, Setup wizard, On a phone]
variables:
  - name: LOCAL_AUTH_ENABLED
    group: Sign-in
    default: "false"
    description: >-
      Set to true to let people sign in with a user name and password. Any
      sign-in setting skips the setup wizard, so set all of sign-in here or
      none of it.
  - name: ADMIN_USERNAME
    group: Sign-in
    default: admin
    description: >-
      The user name of the local admin account.
  - name: ADMIN_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The password of the local admin account. Leave it out to turn that
      account off.
  - name: VIEWER_USERNAME
    group: Sign-in
    default: viewer
    description: >-
      The user name of the local viewer account.
  - name: VIEWER_PASSWORD
    group: Sign-in
    default: ""
    description: >-
      The password of the local viewer account. Leave it out to turn that
      account off.
  - name: PLEX_AUTH_ENABLED
    group: Sign-in
    default: "false"
    description: >-
      Set to true to let members of your Plex server sign in with Plex.
  - name: PLEX_SERVER_MACHINE_ID
    group: Sign-in
    default: ""
    description: >-
      Your Plex server's machine identifier. Needed when Plex sign-in is on.
  - name: PLEX_SERVER_TOKEN
    group: Sign-in
    default: ""
    description: >-
      Your Plex server token. Lets the server owner sign in as admin.
  - name: PLEX_ADMIN_USERS_STR
    group: Sign-in
    default: ""
    description: >-
      Plex user names that get the admin role, comma separated.
  - name: JWT_SECRET
    group: Sign-in
    default: ""
    description: >-
      The sign-in key, at least 32 characters. Leave it out: one is made on
      first start and kept in the data folder.
  - name: DISPATCHARR_URL
    group: Channel sources
    default: ""
    description: >-
      Your Dispatcharr address, like http://192.168.1.20:9191. Browsers play
      streams from it, so use an address other devices can open.
  - name: DISPATCHARR_API_KEY
    group: Channel sources
    default: ""
    description: >-
      The personal API key from your Dispatcharr profile page.
  - name: ERSATZTV_BASE_URL
    group: Channel sources
    default: ""
    description: >-
      Your ErsatzTV address, like http://192.168.1.20:8409.
  - name: ERSATZTV_API_KEY
    group: Channel sources
    default: ""
    description: >-
      Your ErsatzTV API key, for session numbers on the Status page.
  - name: CHAT_ENABLED
    group: Features
    default: "false"
    description: >-
      Set to true to turn on chat.
  - name: GIPHY_API_KEY
    group: Features
    default: ""
    description: >-
      A Giphy API key (developers.giphy.com) to allow GIFs in chat.
  - name: HIGHLIGHT_ENABLED
    group: Features
    default: "false"
    description: >-
      Set to true to let people capture and export clips.
  - name: ZIPLINE_ENABLED
    group: Features
    default: "false"
    description: >-
      Set to true to upload clips to a shared Zipline account.
  - name: ZIPLINE_URL
    group: Features
    default: ""
    description: >-
      Your Zipline address, without /api/upload.
  - name: ZIPLINE_TOKEN
    group: Features
    default: ""
    description: >-
      The Zipline token for the shared account.
  - name: NHL_ENABLED
    group: Features
    default: "false"
    description: >-
      Set to true to show live NHL scores over the player.
  - name: NTFY_ENABLED
    group: Feedback (ntfy)
    default: "false"
    description: >-
      Set to true for a feedback button that sends reports to an ntfy topic.
  - name: NTFY_URL
    group: Feedback (ntfy)
    default: ""
    description: >-
      The ntfy server, like https://ntfy.sh.
  - name: NTFY_TOPIC
    group: Feedback (ntfy)
    default: ""
    description: >-
      The ntfy topic for feedback, like channel-club-feedback.
  - name: NTFY_TOKEN
    group: Feedback (ntfy)
    default: ""
    description: >-
      An ntfy access token. Only needed for protected topics.
  - name: LOG_LEVEL
    group: Logs
    default: INFO
    description: >-
      How much goes in the log: DEBUG, INFO, WARNING or ERROR.
  - name: LOG_FORMAT
    group: Logs
    default: pretty
    description: >-
      pretty for reading, or json for log collectors like Loki.
---

# Channel Club

Channel Club is a live TV player for watching together. Channels come from Dispatcharr and/or ErsatzTV. People sign in with Plex or a local account and either follow one shared Live channel or pick their own.

## Features

- One shared Live channel everyone can follow, or watch your own
- Channel guide from Dispatcharr and ErsatzTV
- Sign in with Plex (members of your server) or a user name and password
- Chromecast built in, and it installs as an app on phones
- Optional chat with GIFs, clip capture and export, Zipline uploads, live NHL scores and a feedback button through ntfy
- Setup wizard in the browser; everything can be changed later in the admin panel

## How to use

1. Open Channel Club from your dashboard.
2. The setup wizard opens. The first person to finish it becomes the admin.
3. Pick how people sign in (Plex or user name and password).
4. Add your Dispatcharr address and API key, or your ErsatzTV address.
5. Pick a channel and start watching. Share the address with friends.

## Before you install

Nothing needs to be set first. Open `http://[ZIMAOS-IP-ADDRESS]:6174` right after installing: whoever finishes the setup wizard first becomes the admin. Use addresses for Dispatcharr and ErsatzTV that other devices can open (like `http://192.168.1.20:9191`), because browsers play the streams from there. All settings can also be added as variables (Variables tab) in the app settings; a setting added that way is locked in the app, and any sign-in setting skips the wizard. The image is amd64 only.
