---
site: https://github.com/petrjancar/habits
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Admin Dashboard, path: /_/, icon: server }
screenshots: [Statistics, Today on a phone, A habit's calendar]
---

# Habits

Habits is a small habit tracker: check off habits each day, keep streaks going and see how consistent you've been. It runs as one PocketBase process, so there is no separate database to look after.

## Features

- Today page: check off today's habits or any earlier day, page through the weeks and see what's coming up
- Schedules: every day, chosen weekdays, or a number of times a week
- Pauses and skips: plan a holiday or skip a sick day without breaking the streak
- Statistics: success rate, best streak, charts and a 52-week calendar
- 16 colours, light and dark theme, JSON backup export and import
- Install it on your phone's home screen as an app (needs https)

## How to use

1. Open Habits from your dashboard.
2. Click Register and make your account.
3. Add your first habit and pick when it is due.
4. Check it off on the Today page each day.

## Before you install

Nothing has to be set. If you also want the PocketBase admin dashboard at `http://[ZIMAOS-IP-ADDRESS]:6171/_/`, set `PB_ADMIN_EMAIL` and `PB_ADMIN_PASSWORD` (at least 8 characters) before you install; the account is made, or its password reset, on every start. In the dashboard you can turn off sign-up for new people and make backups. To use Habits from other devices, open `http://[ZIMAOS-IP-ADDRESS]:6171`. To add it to a phone's home screen, open it over https, for example through a reverse proxy. It is ready a few seconds after install.
