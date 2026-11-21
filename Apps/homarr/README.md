---
site: https://homarr.dev/
services:
  - { name: Dashboard, path: /, icon: globe }
screenshots: [Board]
variables:
  - name: SECRET_ENCRYPTION_KEY
    group: Server
    default: ""
    description: >-
      The key saved passwords and API keys are encrypted with, 64 hex
      characters. It is made on first start and kept in /appdata/secrets.env.
      Only set it to move an old install.
  - name: NO_EXTERNAL_CONNECTION
    group: Server
    default: "false"
    description: >-
      Set to true so Homarr never connects to the internet (no update checks,
      no icon downloads).
  - name: LOG_LEVEL
    group: Server
    default: "info"
    description: >-
      How much goes in the log: debug, info, warn or error.
  - name: AUTH_PROVIDERS
    group: Sign-in
    default: "credentials"
    description: >-
      How people sign in, comma separated: credentials, oidc, ldap.
  - name: AUTH_SESSION_EXPIRY_TIME
    group: Sign-in
    default: "30d"
    description: >-
      How long people stay signed in, like 7d or 12h.
  - name: AUTH_LOGOUT_REDIRECT_URL
    group: Sign-in
    default: ""
    description: >-
      Where to go after signing out.
  - name: AUTH_OIDC_ISSUER
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      Your provider's issuer address, like https://auth.example.com.
  - name: AUTH_OIDC_CLIENT_ID
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The client ID from your provider.
  - name: AUTH_OIDC_CLIENT_SECRET
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The client secret from your provider.
  - name: AUTH_OIDC_CLIENT_NAME
    group: Single sign-on (OIDC)
    default: "OIDC"
    description: >-
      The name on the sign-in button.
  - name: AUTH_OIDC_AUTO_LOGIN
    group: Single sign-on (OIDC)
    default: "false"
    description: >-
      Set to true to go straight to your provider.
  - name: AUTH_OIDC_SCOPE_OVERWRITE
    group: Single sign-on (OIDC)
    default: ""
    description: >-
      The scopes to ask for. Leave it out for openid, email, profile and
      groups.
  - name: AUTH_OIDC_GROUPS_ATTRIBUTE
    group: Single sign-on (OIDC)
    default: "groups"
    description: >-
      The claim that holds the user's groups.
  - name: AUTH_LDAP_URI
    group: LDAP
    default: ""
    description: >-
      Your LDAP server, like ldap://ldap.example.com:389.
  - name: AUTH_LDAP_BASE
    group: LDAP
    default: ""
    description: >-
      Where to look for users, like dc=example,dc=com.
  - name: AUTH_LDAP_BIND_DN
    group: LDAP
    default: ""
    description: >-
      The account Homarr searches with.
  - name: AUTH_LDAP_BIND_PASSWORD
    group: LDAP
    default: ""
    description: >-
      Its password.
  - name: AUTH_LDAP_SEARCH_SCOPE
    group: LDAP
    default: "base"
    description: >-
      base, one or sub.
  - name: AUTH_LDAP_USERNAME_ATTRIBUTE
    group: LDAP
    default: "uid"
    description: >-
      The attribute with the user name.
  - name: AUTH_LDAP_USER_MAIL_ATTRIBUTE
    group: LDAP
    default: "mail"
    description: >-
      The attribute with the email.
  - name: AUTH_LDAP_GROUP_CLASS
    group: LDAP
    default: "groupOfUniqueNames"
    description: >-
      The object class of groups.
  - name: AUTH_LDAP_GROUP_MEMBER_ATTRIBUTE
    group: LDAP
    default: "member"
    description: >-
      The group attribute that lists members.
---

# Homarr

Homarr is a start page for your home server. Put all your apps on a board you arrange by drag and drop, and add widgets that show what they are doing: downloads, media, calendars, weather and system load. It connects to more than 50 apps.

## Features

- Boards you build by drag and drop, no config files
- Widgets for downloads, media servers, calendars, weather and more
- Integrations with Sonarr, Radarr, Jellyfin, Plex, Pi-hole, Home Assistant and many others
- Search across your apps from one box
- Users, groups and permissions, with OIDC and LDAP sign-in
- Thousands of built-in app icons

## How to use

1. Open Homarr from your dashboard.
2. Follow the onboarding: make the admin account and pick your settings.
3. Make a board and click Edit to add apps and widgets.
4. Add integrations in Management, then use them in widgets.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6774`. There is no account yet: the onboarding page asks you to make the admin account. The encryption key Homarr needs is made for you on first start and kept in `/DATA/AppData/homarr/appdata`. OIDC, LDAP and the other settings are in the Variables tab and are added in the app settings. The Docker widgets are not set up, since they need access to the Docker socket. It is ready in about a minute.
