---
site: https://certimate.me/
services:
  - { name: Web UI, path: /, icon: globe }
screenshots: [Workflow]
variables: []
---

# Certimate

Certimate gets SSL certificates for your domains from Let's Encrypt and other free authorities, renews them before they run out, and deploys them to your servers, CDNs and cloud services. Build each step as a workflow and let it run on a schedule.

## Features

- Single, multi-domain and wildcard certificates, and IP certificates
- DNS-01 and HTTP-01 checks, with 70+ DNS providers
- Deploys to 160+ places: servers over SSH, Kubernetes, CDNs, WAFs, load balancers and clouds
- Let's Encrypt, ZeroSSL, Google Trust Services and more
- PEM, PFX and JKS formats, RSA or ECC keys
- Alerts by email, Discord, Slack, Telegram and more

## How to use

1. Open Certimate from your dashboard.
2. Sign in with the email and the password from the app's logs (the box marked CREDENTIALS).
3. Add your DNS provider and where to deploy under Credentials.
4. Make a workflow: request a certificate, then deploy it.
5. Turn the workflow on. Certimate renews it from then on.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6784`. The first admin is `CERTIMATE_ADMIN_USERNAME` (`admin@example.com` unless you change it) with a password made on first start, shown in the app's logs in the box marked CREDENTIALS and saved in `/DATA/AppData/certimate/pb_data/.admin_password`, so the upstream default password is never used. Everything else (providers, workflows, alerts) is set up inside Certimate. It is ready in under a minute.
