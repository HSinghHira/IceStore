---
source: https://github.com/RSS-Bridge/rss-bridge
screenshots: [Home, Filter bridge, Feed formats]
services:
  - { name: Web App, path: /, icon: globe }
---

# RSS-Bridge

RSS-Bridge turns social networks, video sites, shops and news pages without feeds into RSS and Atom feeds you can follow in FreshRSS, Miniflux or any feed reader. Pick a bridge, fill in the form and copy the feed link.

## Features

- Over 400 bridges for YouTube, Reddit, Telegram channels, Bandcamp, shops and more
- Atom, RSS, JSON, HTML and Mrss output
- Choose which bridges are on with a whitelist
- Add your own bridges as PHP files

## How to use

1. Open RSS-Bridge and find a bridge with the search box.
2. Fill in its form and press a format, like Atom.
3. Copy the address and add it to your feed reader.

## Before you install

RSS-Bridge has no login, so anyone on your network can make feeds with it. Settings and the list of turned-on bridges live in /DATA/AppData/rss-bridge/config: copy config.default.ini.php from the RSS-Bridge repo there as config.ini.php, and add whitelist.txt with one bridge name per line (or * for all). FreshRSS from IceStore blocks feeds on your own network until you list this one in its INTERNAL_HOST_ALLOWLIST.
