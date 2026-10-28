---
name: iSponsorBlockTV
site: https://github.com/dmunozv04/iSponsorBlockTV
source: https://github.com/dmunozv04/iSponsorBlockTV
services:
  - { name: Setup Wizard, path: /, icon: monitor }
variables:
  - name: ISPONSORBLOCKTV_SETUP_USERNAME
    group: Setup page
    default: ""
    description: >-
      A username for the setup page. Set it together with
      ISPONSORBLOCKTV_SETUP_PASSWORD so the page asks for both. Leave both out
      to keep the page open on your home network.
  - name: ISPONSORBLOCKTV_SETUP_PASSWORD
    group: Setup page
    default: ""
    description: >-
      A password for the setup page. Only works with
      ISPONSORBLOCKTV_SETUP_USERNAME set too.
  - name: ISPONSORBLOCKTV_DEBUG
    group: Logs
    default: "false"
    description: >-
      Set to true for detailed logs, to find out why a TV doesn't connect or
      a segment isn't skipped.
---

# iSponsorBlockTV

iSponsorBlockTV connects to the YouTube app on your TV, like a phone would, and skips sponsor segments, intros and other parts using the SponsorBlock database. It can also mute ads and press "Skip Ad" for you.

## Features

- Skips sponsors, intros, outros, self-promotion, reminders to subscribe and more, you pick which
- Mutes ads and presses "Skip Ad" as soon as it shows up
- Works with Apple TV, Samsung and LG TVs, Android TV, Google TV, Chromecast, Roku, Fire TV, Xbox, PlayStation and Nintendo Switch
- Finds TVs on your network by itself, or pair one with a TV code
- Channel allow list, so creators you like are never skipped
- Setup wizard right in your browser, no terminal needed

## How to use

1. Open iSponsorBlockTV from your dashboard, or go to `http://[ZIMAOS-IP-ADDRESS]:6129`. You see the setup wizard.
2. Add your TV: let the wizard find it, or pair it with the code from the YouTube app on your TV (Settings, then Link with TV code).
3. Pick what to skip, then save and exit the wizard.
4. Play a video on your TV. Sponsor parts are skipped by themselves.

There is nothing else to open: the skipper runs in the background and starts again by itself when you save new settings. Open the setup page again any time to add a TV or change what is skipped.

## Before you install

Nothing needs to be set first. The app starts in a few seconds and waits until you pair a TV in the setup wizard; the log says "no TV paired yet" until then. It uses host networking so the wizard can find TVs on your network; pairing with a TV code works too. The setup page has no password unless you add `ISPONSORBLOCKTV_SETUP_USERNAME` and `ISPONSORBLOCKTV_SETUP_PASSWORD` (Variables tab, added in the app settings), so don't open port 6129 to the internet. Muting ads doesn't work when the sound goes to another speaker over AirPlay, and YouTube Shorts aren't fully supported.
