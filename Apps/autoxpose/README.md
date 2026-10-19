---
site: https://github.com/mostafa-wahied/autoxpose
services:
  - { name: Web UI, path: /, icon: globe }
screenshots: [Dashboard]
variables:
  - name: LOG_LEVEL
    group: Logs
    default: info
    description: >-
      How much detail goes in the log. One of debug, info, warn or error.
  - name: DOCKER_HOST
    group: Docker
    default: ""
    description: >-
      Use a Docker socket proxy instead of the mounted Docker socket, like
      tcp://192.168.1.10:2375. Leave it out to use the socket.
---

# AutoXpose

AutoXpose watches your Docker containers. When it finds one with an autoxpose label, it creates the DNS record and sets up your reverse proxy with HTTPS for you.

## Features

- Finds running containers that have autoxpose labels and lists them
- Creates and removes DNS records, and checks that they work, on Cloudflare, Netlify, DigitalOcean, Porkbun, Aliyun or Tencent Cloud DNSPod
- Sets up Nginx Proxy Manager or Caddy as the reverse proxy, and detects HTTP or HTTPS on its own
- Auto-expose mode (`autoxpose.enable=auto`) skips the "Expose" click
- Attach an existing Nginx Proxy Manager access list with a label
- Finds and removes old DNS records and proxy hosts left behind by removed containers
- One container with a built-in SQLite database, no extra database needed

## How to use

1. Open AutoXpose from your dashboard.
2. Go to Settings and add a DNS provider and a proxy provider (Nginx Proxy Manager or Caddy).
3. Add the label `autoxpose.enable=true` (or `auto`) to a container you want to reach from the internet. Add `autoxpose.subdomain=myapp` to pick its name. Then recreate that container.
4. Open AutoXpose again. The container shows up under Discovered Services. Click "Expose" if you used `enable=true`.
5. You can change provider settings, `SERVER_IP` and `LAN_IP` later from Settings.

## Labels

| Label | What it does |
| :--- | :--- |
| `autoxpose.enable` | `true` shows the container in AutoXpose, `auto` also exposes it right away |
| `autoxpose.subdomain` | The subdomain to use. Default: the container name |
| `autoxpose.port` | Use this port instead of the one AutoXpose finds |
| `autoxpose.scheme` | Use `http` or `https` instead of the one AutoXpose finds |
| `autoxpose.name` | The name shown in AutoXpose |
| `autoxpose.npm.access_list` | The name of an Nginx Proxy Manager access list to attach, or `public` to remove one |

## Before you install

Set `SERVER_IP` to your public IP address and `LAN_IP` to the local IP address of your ZimaOS box. AutoXpose reads the Docker socket (read-only) to find your containers. You need a DNS provider account and Nginx Proxy Manager or Caddy already running. More settings are in the Variables tab and are added in the app settings. AutoXpose is ready a few seconds after it starts.
