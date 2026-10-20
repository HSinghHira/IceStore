---
site: https://www.spiderfoot.net/
source: https://github.com/smicallef/spiderfoot
services:
  - { name: Web UI, path: /, icon: search }
---

# SpiderFoot

SpiderFoot automates open-source intelligence (OSINT) gathering. It asks over 200 data sources to map out everything public about a target, like a one-click recon report for your own attack surface or any domain you are looking into.

## Features

- 200+ modules covering DNS, WHOIS, breach databases, threat feeds, social media and more
- Modules feed each other for deeper, automatic correlation
- Built-in correlation rules flag risks for you
- Web UI and CLI, with CSV, JSON and GEXF export
- Scans and settings survive restarts

## How to use

1. Open SpiderFoot from your dashboard.
2. Click "New Scan", give it a name and enter a target: a domain, IP, email or name.
3. Pick modules or a preset, like "Passive", and start the scan.
4. Watch results come in, then export them as CSV, JSON or GEXF.
5. Add optional API keys (Shodan, HaveIBeenPwned and others) under Settings to unlock extra modules.

## Before you install

Nothing needs to be set first. SpiderFoot has no login screen, so anyone who can reach port 6117 can use it. If your server is reachable from outside your home network, put SpiderFoot behind a reverse proxy with a login first. API keys are optional and added later in the app's Settings. This image is for amd64 only.
