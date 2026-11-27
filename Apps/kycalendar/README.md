---
site: https://busnes.app/kycalendar.html
source: https://github.com/Busnes-app/KyCalendar
services:
  - { name: Web App, path: /, icon: globe }
screenshots: []
variables:
  - name: KY_SESSION_SECRET
    group: Keys
    default: ""
    description: >-
      The secret that keeps browser sign-ins valid. KyCalendar makes it on
      first start when left empty and keeps it in the data folder. Never change
      it.
  - name: KY_COOKIE_SECURE
    group: Reverse proxy
    default: ""
    description: >-
      Leave empty to mark cookies secure for KyCalendar's required https
      address. Set true or false only when your proxy cannot report the
      original address correctly.
  - name: KY_ALLOW_INSECURE_HTTP
    group: Reverse proxy
    default: ""
    description: >-
      Leave empty. KyCalendar needs an https address for its sign-in security
      check, so do not turn this on for a normal install.
  - name: KY_TRUSTED_PROXIES
    group: Reverse proxy
    default: ""
    description: >-
      The address KyCalendar sees your reverse proxy connect from, such as
      172.18.0.2/32. Set only your proxy so sign-in limits use visitors' real
      addresses.
  - name: KY_RATE_LIMIT_EXEMPT_NETWORKS
    group: Sign-in protection
    default: ""
    description: >-
      Office networks that skip per-address sign-in and CalDAV limits, such as
      192.168.1.0/24. Never add your proxy, guest Wi-Fi or a shared network.
  - name: KY_SCIM_TOKEN
    group: KyIdentity provisioning
    default: ""
    description: >-
      A secret with at least 32 characters for KyIdentity to create and manage
      people. Leave empty when you manage local accounts yourself.
  - name: KY_SSO_ENABLED
    group: KyIdentity sign-in
    default: "true"
    description: >-
      Set to false to turn off single sign-on. Leave it true for KyIdentity or
      another OpenID Connect provider.
  - name: KY_SSO_AUTO_PROVISION
    group: KyIdentity sign-in
    default: "true"
    description: >-
      Set to false when an administrator should create people manually. Leave
      it true to create an account when an allowed person first signs in.
  - name: KY_KYSIGNON_ISSUER
    group: KyIdentity sign-in
    default: ""
    description: >-
      Your KyIdentity address, such as https://id.example.com. Setting it
      enables KyIdentity sign-in.
  - name: KY_KYSIGNON_CLIENT_ID
    group: KyIdentity sign-in
    default: ""
    description: >-
      The client ID KyIdentity gave KyCalendar.
  - name: KY_KYSIGNON_SECRET
    group: KyIdentity sign-in
    default: ""
    description: >-
      The client secret KyIdentity gave KyCalendar. Keep it private.
  - name: KY_KYSIGNON_HMAC_SECRET
    group: KyIdentity sign-in
    default: ""
    description: >-
      The shared secret KyIdentity gave KyCalendar for signed sign-in
      messages. Keep it private.
  - name: KYCALENDAR_BACKUP_KEEP
    group: Backups
    default: "7"
    description: >-
      Number of local encrypted backup capsules to keep.
  - name: KYCALENDAR_BACKUP_DEPOSIT_INTERVAL
    group: Backups
    default: 24h
    description: >-
      How often KyCalendar makes an encrypted backup capsule. Use a duration
      such as 24h.
  - name: KYCALENDAR_BACKUP_ALLOW_PRIVATE_RECOVERY
    group: Backups
    default: "false"
    description: >-
      Set to true only when your recovery service uses a private network
      address. Keep it false for normal public https recovery addresses.
  - name: KYCALENDAR_SCHEDULING
    group: Invitations
    default: ""
    description: >-
      Leave empty to turn invitations on automatically when KyPost is linked.
      Set true or false to force them on or off.
  - name: KYCALENDAR_KYPOST_URL
    group: Invitations
    default: ""
    description: >-
      Https address of a separate KyPost service for sending calendar
      invitations. Fill this and KYCALENDAR_KYPOST_SECRET_FILE together, or
      leave both empty. KyCalendar will not start with only one.
  - name: KYCALENDAR_KYPOST_SECRET_FILE
    group: Invitations
    default: ""
    description: >-
      Path inside the container to the KyPost shared-secret file. Fill this
      and KYCALENDAR_KYPOST_URL together, or leave both empty. KyCalendar will
      not start with only one.
  - name: KYCALENDAR_KYPOST_ALLOW_PRIVATE
    group: Invitations
    default: "false"
    description: >-
      Set to true only when the KyPost address is on your private network.
  - name: KYCALENDAR_KYMESSAGES_URL
    group: Video meetings
    default: ""
    description: >-
      Https address of a separate KyMessages service for video meetings. Fill
      this and KYCALENDAR_KYMESSAGES_SECRET_FILE together, or leave both empty.
      KyCalendar will not start with only one.
  - name: KYCALENDAR_KYMESSAGES_SECRET_FILE
    group: Video meetings
    default: ""
    description: >-
      Path inside the container to the KyMessages shared-secret file. Fill this
      and KYCALENDAR_KYMESSAGES_URL together, or leave both empty. KyCalendar
      will not start with only one.
  - name: KYCALENDAR_KYMESSAGES_ALLOW_PRIVATE
    group: Video meetings
    default: "false"
    description: >-
      Set to true only when the KyMessages address is on your private network.
  - name: KY_CALENDAR_MAX_BYTES_TOTAL
    group: Storage limits
    default: "41943040"
    description: >-
      Largest total size of calendar data, in bytes. The default is 40 MiB.
  - name: KY_CALENDAR_MAX_BYTES_PER_USER
    group: Storage limits
    default: ""
    description: >-
      Largest calendar-data size for one person or group, in bytes. Leave empty
      to use KyCalendar's default share of the total limit.
---

# KyCalendar

KyCalendar is a private calendar for the Busnes Ky Suite. It gives each person and group their own calendars in the web app and in CalDAV clients such as iPhone Calendar, macOS Calendar, DAVx5 and Thunderbird. It works with local accounts or optional KyIdentity sign-in.

## Features

- Personal calendars, events and shared group schedules
- Local accounts and groups, or optional KyIdentity single sign-on and provisioning
- CalDAV for phones, computers and compatible calendar apps
- Per-device app passwords for CalDAV clients and scoped access for AI agents
- Optional KyPost invitations and KyMessages video meetings
- Encrypted backups and a documented recovery process

## How to use

1. Set up an https reverse proxy, such as Nginx Proxy Manager, with your own domain. Point it at `http://[ZIMAOS-IP-ADDRESS]:6876`, then set `KY_APP_URL` to the proxy's exact https address.
2. Open the app logs and find the box marked **CREDENTIALS**. It has the first `admin` password when `KY_ADMIN_PASSWORD` was left empty; otherwise use the password you set. The made password is also in `initial-admin-password` in the data folder.
3. Open KyCalendar at the https address in `KY_APP_URL`, sign in as `admin` and change the password. Then create everyday people and local groups under **People**.
4. Create a calendar and an event in the web app.
5. Sign in as an everyday user, not `admin`, then make an app password with the `dav` scope in **Settings** → **Phones & apps**. Connect a phone or computer to your own https address, such as `https://calendar.example.com/dav/`.
6. If you use KyIdentity, connect it for single sign-on and provisioning. Connect KyPost only when you want email invitations.

## Before you install

**KyCalendar requires https to sign in.** Its browser security check only runs on a secure connection. Set up a reverse proxy, such as Nginx Proxy Manager, with your own domain and point it at `http://[ZIMAOS-IP-ADDRESS]:6876`. Set `KY_APP_URL` to the proxy's exact https address, such as `https://calendar.example.com`, before you install. Add the proxy's exact address to `KY_TRUSTED_PROXIES` so KyCalendar can see the real visitor address. Opening `http://[ZIMAOS-IP-ADDRESS]:6876` directly shows the sign-in page, but sign-in fails. CalDAV also needs the https address and an everyday account with an app password.

When `KY_ADMIN_PASSWORD` is empty, the first administrator password is in the **CREDENTIALS** box in the app logs and also in `initial-admin-password` in `/DATA/AppData/kycalendar/data` (open it with the Files app). If you set `KY_ADMIN_PASSWORD`, use that instead. Change the password after the first sign-in and remove the file. Back up both the data and backups folders: they hold the calendar data, keys and encrypted recovery capsules. More optional settings are in the Variables tab; add them in the app settings.
