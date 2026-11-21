---
site: https://webdecoy.com/product/fcaptcha-demo/
services:
  - { name: Interactive demo, path: /demo/, icon: globe }
  - { name: Health check, path: /health, icon: server }
screenshots: [The FCaptcha checkbox demo and JavaScript integration example]
variables:
  - name: FCAPTCHA_SECRET
    group: Credentials
    default: ""
    description: Generate with `openssl rand -hex 32`, or leave blank for a private key on first start.
  - name: FCAPTCHA_VERIFY_SECRET
    group: Credentials
    default: ""
    description: Generate with `openssl rand -hex 32` separately, or leave blank for a separate private key on first start.
  - name: TRUSTED_PROXIES
    group: Networking
    default: ""
    description: Addresses or CIDRs of your actual reverse proxies. Leave blank to use the upstream loopback-only default.
  - name: FCAPTCHA_ALLOWED_HOSTNAMES
    group: Networking
    default: ""
    description: Comma-separated hostnames allowed to mint tokens. Leave blank for the demo and unrestricted origins.
  - name: FCAPTCHA_SITE_KEYS
    group: Integration
    default: ""
    description: Comma-separated accepted site keys. Leave blank for zero-config self-hosting.
  - name: REDIS_URL
    group: Scaling
    default: ""
    description: Optional URL to a Redis instance for shared security state. Otherwise FCaptcha keeps state in memory.
---

# FCaptcha

FCaptcha provides a JavaScript widget that collects browser signals and a server endpoint that verifies tokens for app actions such as form submissions.

## Try the demo

Open FCaptcha from your dashboard, or visit `http://[ZIMAOS-IP-ADDRESS]:6765/demo/`. The same service serves `/fcaptcha.js` and `/health`.

## Connect an application

Follow the [FCaptcha quickstart](https://docs.webdecoy.com/fcaptcha/quickstart/) to add the widget and verify tokens from your backend. The second line of the app's private `keys/keypair` file is the backend verification key. An administrator can read that line locally with `docker exec -u 65532:65532 fcaptcha sed -n '2p' /fcaptcha-data/keys/keypair`. Keep both keys on the server and back up the data directory securely.

Configure HTTPS and set `TRUSTED_PROXIES` to the addresses or CIDRs of your actual ingress before exposing the service publicly. See the [hardening guide](https://github.com/WebDecoy/FCaptcha/blob/main/HARDENING.md).
