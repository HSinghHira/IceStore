---
services:
  - { name: Setup Page, path: /, icon: plug }
variables:
  - name: SPORT_TYPES
    group: What to import
    default: all
    description: >-
      all imports every activity with GPS. To limit it, list Strava sport
      types, comma separated, like Run,TrailRun,Ride.
  - name: SKIP_VIRTUAL
    group: What to import
    default: "true"
    description: >-
      Set to false to also import virtual activities (Zwift, ROUVY,
      MyWhoosh and indoor trainer rides).
  - name: SYNC_INTERVAL_MINUTES
    group: Timing
    default: "60"
    description: >-
      How many minutes to wait between checks for new activities.
  - name: LOOKBACK_DAYS
    group: Timing
    default: "14"
    description: >-
      How many days back each check looks, for activities your watch
      uploads late.
  - name: DRY_RUN
    group: Testing
    default: "false"
    description: >-
      Set to true to only write GPX files to the gpx folder in the data
      folder and upload nothing.
---

# Strava to Dawarich

Strava to Dawarich (strava-dawarich-sync) copies your Strava activities into your own Dawarich, so your runs, rides and hikes show up in your location history. The first run imports your whole Strava history, then it checks for new activities every hour.

## Features

- Imports every activity with GPS: runs, rides, hikes, swims and more
- Skips virtual rides and runs (Zwift, ROUVY and others), so no fake trips end up on your map
- Never imports anything twice, even if its data folder is lost
- Waits by itself when Strava's request limits are reached
- Setup page in the browser to connect Strava, no terminal needed

## How to use

1. Make your own Strava API app at https://www.strava.com/settings/api. For Authorization Callback Domain, type `localhost`. Copy its Client ID and Client Secret.
2. Copy the API key from Dawarich, Account settings.
3. Put all of them in the app settings and start it.
4. Open `http://[ZIMAOS-IP-ADDRESS]:6176`, click the orange button and Authorize on Strava, leaving every box ticked.
5. Your browser shows an error page at `localhost`. That is expected: copy the whole address, paste it on the setup page and click Connect.
6. Your activities appear in Dawarich under Imports, named `strava_<id>.gpx`.

## Before you install

**You must set `DAWARICH_URL` first.** For Dawarich from IceStore on this ZimaOS it is `http://[ZIMAOS-IP-ADDRESS]:6175`: replace `[ZIMAOS-IP-ADDRESS]` with your ZimaOS IP, like `http://192.168.1.20:6175`. For a Dawarich elsewhere, type its address. Also fill in `STRAVA_CLIENT_ID`, `STRAVA_CLIENT_SECRET` and `DAWARICH_API_KEY`; the sync waits until all four are set and Strava is connected. The setup page at port 6176 shows what is missing. With many activities the first import can take more than a day, because Strava allows only about 100 requests every 15 minutes; "rate limit reached, waiting" in the log is normal. The other settings are in the Variables tab; add them in the app settings.
