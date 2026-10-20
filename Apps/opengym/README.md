---
name: openGym
site: https://gitlab.com/DuarteSantos8/opengym
source: https://gitlab.com/DuarteSantos8/opengym
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: RP_NAME
    group: Passkeys
    default: openGym
    description: >-
      The name shown in the passkey prompt when signing in. Add it to the api
      service.
  - name: SESSION_DAYS
    group: Sign-up and accounts
    default: "90"
    description: >-
      How many days a sign-in lasts. Lower it if openGym is reachable from the
      internet. Add it to the api service.
  - name: INVITE_ONLY
    group: Sign-up and accounts
    default: ""
    description: >-
      Set to 1 so new profiles need an invite code. Add it to the api service.
  - name: FIRST_USER_ADMIN
    group: Sign-up and accounts
    default: ""
    description: >-
      Set to 1 so the first profile on a new install becomes the admin. Add it
      to the api service.
  - name: ADMIN_UIDS
    group: Sign-up and accounts
    default: ""
    description: >-
      Account IDs that get the admin dashboard, separated by commas. Add it to
      the api service.
  - name: ALLOW_GUEST
    group: Sign-up and accounts
    default: "1"
    description: >-
      Set to 0 to remove "Continue without account". Add it to the api
      service.
  - name: PASSWORD_LOGIN
    group: Sign-up and accounts
    default: ""
    description: >-
      Set to 1 to also allow name-and-password sign-in. Add it to the api
      service.
  - name: DEFAULT_LANG
    group: Server
    default: ""
    description: >-
      The language for sign-in and new profiles, like en or de. Leave it out
      to use the browser's language. Add it to the api service.
  - name: TRUST_PROXY
    group: Server
    default: ""
    description: >-
      Set to 1 when openGym is behind a reverse proxy, so it sees real
      visitor addresses. Add it to the api service.
  - name: VAPID_SUBJECT
    group: Notifications
    default: ""
    description: >-
      Contact address given to push services, like mailto:you@example.com.
      Leave it out to use ORIGIN. Add it to the api service.
  - name: AUDIT_LOG
    group: Logs
    default: "1"
    description: >-
      Set to 0 to turn the activity log off. Add it to the api service.
  - name: AUDIT_DAYS
    group: Logs
    default: "90"
    description: >-
      Days of activity log to keep. Add it to the api service.
  - name: MEDIA_UPLOADS
    group: Uploads
    default: "1"
    description: >-
      Set to 0 to turn off photo and video uploads. Add it to the api service.
  - name: MEDIA_QUOTA_MB
    group: Uploads
    default: "200"
    description: >-
      Storage per profile in MB. Set to 0 for no limit. Add it to the api
      service.
---

# openGym

openGym is a self-hosted gym and body-weight tracker: plan routines, log workouts (supersets and cardio included), and track your weight and progress over time, all stored on your own server.

## Features

- Weekly routine planner and guided workout logging, with supersets, drop-sets, rest-pause and planned warm-ups
- Body-weight tracking with a goal line and progress charts, plus estimated 1RM and other stats
- Passkey (WebAuthn) sign-in, with optional invite-only signup and an admin dashboard
- Push notifications for workout-day reminders
- Everything is stored as plain files, no separate database to run or back up
- A helper step downloads the exercise photo and GIF library (about 140 MB) once on first start

## How to use

1. Open openGym from your dashboard.
2. Tap "Create profile" and register a passkey.
3. Build your first weekly routine, then start a guided workout and log your sets.
4. Add a body-weight entry and set a goal line under the Weight tab.
5. Turn on the admin dashboard, invite-only signup or the AI Coach later from Settings.

## Before you install

Set `RP_ID` and `ORIGIN` in the api service. They must point at the same address, or sign-in fails. To test on the same computer only, use `localhost` and `http://localhost:6115`. To use openGym from your phone, you need a real domain with HTTPS in front, like `gym.example.com` and `https://gym.example.com`. Pick your final address before inviting people: moving later breaks every passkey. The first start downloads about 140 MB of exercise pictures, so give it a few minutes. More settings are in the Variables tab; add them to the api service in the app settings.
