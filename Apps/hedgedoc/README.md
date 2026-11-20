---
site: https://hedgedoc.org/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: Features note, path: /features, icon: info }
screenshots: [Editor and preview, Editing a note]
variables:
  - name: CMD_DOMAIN
    group: Server
    default: ""
    description: >-
      Your domain, like notes.example.com. Leave it out and HedgeDoc works on
      any address. Needed for sign-in with GitHub or OAuth2.
  - name: CMD_PROTOCOL_USESSL
    group: Server
    default: "false"
    description: >-
      Set to true when people open HedgeDoc over https through a reverse
      proxy. Only used when CMD_DOMAIN is set.
  - name: CMD_URL_ADDPORT
    group: Server
    default: "false"
    description: >-
      Set to true to add the port to links, like
      http://192.168.1.20:6759. Only used when CMD_DOMAIN is set.
  - name: CMD_SESSION_SECRET
    group: Server
    default: ""
    description: >-
      The key that signs sign-in cookies. It is made on first start and kept
      in the data folder as .session_secret. Only set it to use your own.
  - name: CMD_SESSION_LIFE
    group: Server
    default: "1209600000"
    description: >-
      How long people stay signed in, in milliseconds. The default is 14
      days.
  - name: CMD_DB_URL
    group: Server
    default: ""
    description: >-
      Use your own PostgreSQL or MariaDB, like
      postgres://user:password@192.168.1.20:5432/hedgedoc. Leave it out to
      keep the built-in SQLite file.
  - name: CMD_LOGLEVEL
    group: Logs
    default: info
    description: >-
      How much HedgeDoc writes to the log: error, warn, info or debug.
  - name: CMD_EMAIL
    group: Sign-up and accounts
    default: "true"
    description: >-
      Set to false to turn off sign-in with email and password, for example
      when everyone signs in with OAuth2.
  - name: CMD_ALLOW_ANONYMOUS_EDITS
    group: Sign-up and accounts
    default: "false"
    description: >-
      With CMD_ALLOW_ANONYMOUS set to false: set this to true so people who
      aren't signed in can still edit notes marked "freely".
  - name: CMD_ALLOW_FREEURL
    group: Notes
    default: "false"
    description: >-
      Set to true to make a new note by opening any address, like
      /meeting-2026-11-21.
  - name: CMD_DEFAULT_PERMISSION
    group: Notes
    default: editable
    description: >-
      Who may change new notes: freely, editable, limited, locked, protected
      or private.
  - name: CMD_ENABLE_UPLOADS
    group: Notes
    default: all
    description: >-
      Who may upload images: all, registered or none.
  - name: CMD_DOCUMENT_MAX_LENGTH
    group: Notes
    default: "100000"
    description: >-
      The longest a note can be, in characters.
  - name: CMD_ALLOW_GRAVATAR
    group: Notes
    default: "true"
    description: >-
      Set to false so profile pictures aren't loaded from Libravatar.
  - name: CMD_IMAGE_UPLOAD_TYPE
    group: Notes
    default: filesystem
    description: >-
      Where uploaded images go: filesystem (the uploads folder), s3, minio,
      imgur, azure or lutim. The others need their own settings from the
      HedgeDoc docs.
  - name: CMD_GITHUB_CLIENTID
    group: Sign in with GitHub
    default: ""
    description: >-
      The client ID of your GitHub OAuth app. Also set CMD_DOMAIN.
  - name: CMD_GITHUB_CLIENTSECRET
    group: Sign in with GitHub
    default: ""
    description: >-
      The client secret of your GitHub OAuth app.
  - name: CMD_OAUTH2_PROVIDERNAME
    group: Sign in with OAuth2 (Pocket ID, Authentik, Keycloak)
    default: ""
    description: >-
      The name on the sign-in button, like Pocket ID.
  - name: CMD_OAUTH2_CLIENT_ID
    group: Sign in with OAuth2 (Pocket ID, Authentik, Keycloak)
    default: ""
    description: >-
      The client ID from your provider. The callback address to enter there
      is your HedgeDoc address plus /auth/oauth2/callback.
  - name: CMD_OAUTH2_CLIENT_SECRET
    group: Sign in with OAuth2 (Pocket ID, Authentik, Keycloak)
    default: ""
    description: >-
      The client secret from your provider.
  - name: CMD_OAUTH2_AUTHORIZATION_URL
    group: Sign in with OAuth2 (Pocket ID, Authentik, Keycloak)
    default: ""
    description: >-
      The provider's authorize address.
  - name: CMD_OAUTH2_TOKEN_URL
    group: Sign in with OAuth2 (Pocket ID, Authentik, Keycloak)
    default: ""
    description: >-
      The provider's token address.
  - name: CMD_OAUTH2_USER_PROFILE_URL
    group: Sign in with OAuth2 (Pocket ID, Authentik, Keycloak)
    default: ""
    description: >-
      The provider's userinfo address.
  - name: CMD_OAUTH2_SCOPE
    group: Sign in with OAuth2 (Pocket ID, Authentik, Keycloak)
    default: ""
    description: >-
      The scopes to ask for, like openid email profile.
  - name: CMD_OAUTH2_USER_PROFILE_USERNAME_ATTR
    group: Sign in with OAuth2 (Pocket ID, Authentik, Keycloak)
    default: ""
    description: >-
      Which field is the user name, like preferred_username.
  - name: CMD_OAUTH2_USER_PROFILE_DISPLAY_NAME_ATTR
    group: Sign in with OAuth2 (Pocket ID, Authentik, Keycloak)
    default: ""
    description: >-
      Which field is the display name, like name.
  - name: CMD_OAUTH2_USER_PROFILE_EMAIL_ATTR
    group: Sign in with OAuth2 (Pocket ID, Authentik, Keycloak)
    default: ""
    description: >-
      Which field is the email, like email.
---

# HedgeDoc

HedgeDoc is a Markdown editor in your browser that several people can type in at the same time. Use it for meeting notes, plans, slides and diagrams. The SQLite database is built in, so it is one container with nothing else to set up.

## Features

- Everyone sees each other's typing live, with the preview next to it
- Markdown with tables, checklists, math, code and emoji
- Diagrams with Mermaid, PlantUML, Graphviz and more
- Turn a note into slides with one click
- Share a note to read, to edit, or keep it private
- Note history, so you can go back to an older version

## How to use

1. Open HedgeDoc from your dashboard.
2. Click Sign In, then Register, and make your account with an email and password.
3. Click New note and start typing Markdown on the left.
4. Click Share to copy a link for others, and set who may edit under the note's permission menu.
5. When everyone has an account, set `CMD_ALLOW_EMAIL_REGISTER` to `false` in the app settings.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6759`. There is no admin account: the first person makes an account with Sign In, then Register. After everyone has one, set `CMD_ALLOW_EMAIL_REGISTER=false`; set `CMD_ALLOW_ANONYMOUS=false` if only signed-in people should make notes. A session secret is made on first start, so people stay signed in across restarts. Sign-in with GitHub or OAuth2, a domain and the other settings are in the Variables tab and are added in the app settings. It is ready in about a minute.
