---
site: https://dokploy.com
services:
  - { name: Dashboard, path: /, icon: globe }
screenshots: [Compose stack, Deployments, Domains]
variables:
  - name: TRAEFIK_HTTP3_PORT
    group: Traefik
    default: "6185"
    description: >-
      The UDP port for HTTP/3. Leave it out to use TRAEFIK_SSL_PORT.
  - name: TRAEFIK_VERSION
    group: Traefik
    default: ""
    description: >-
      The Traefik version to run, like 3.6.25. Leave it out to use the one
      this Dokploy version comes with.
  - name: ADVERTISE_ADDR
    group: Docker Swarm
    default: ""
    description: >-
      The address Docker Swarm is set up with, only used when the swarm is
      first made. Leave it out for 127.0.0.1. Set it to your ZimaOS IP to add
      other servers to the swarm later.
  - name: DOCKER_SWARM_INIT_ARGS
    group: Docker Swarm
    default: ""
    description: >-
      More options for docker swarm init, only used when the swarm is first
      made. Use --default-addr-pool 172.20.0.0/16
      --default-addr-pool-mask-length 24 if your home network uses 10.x.x.x
      addresses.
  - name: DOKPLOY_DOCKER_API_VERSION
    group: Docker Swarm
    default: ""
    description: >-
      The Docker API version to talk to, like 1.44. Only needed if your
      Docker is older than Dokploy expects.
  - name: BETTER_AUTH_SECRET
    group: Secrets
    default: ""
    description: >-
      Your own sign-in key. Leave it out: each install makes its own on first
      start and keeps it in the data folder as .better_auth_secret. Changing
      it signs everyone out.
  - name: OPENAPI_MAX_JSON_BODY_SIZE
    group: API
    default: "10485760"
    description: >-
      The largest JSON request the API accepts, in bytes.
  - name: OPENAPI_MAX_UPLOAD_SIZE
    group: API
    default: "1073741824"
    description: >-
      The largest file upload the API accepts, in bytes.
---

# Dokploy

Dokploy deploys your apps and databases on your own server, like your own Vercel, Heroku or Netlify. Point it at a Git repository or a Docker image, and it builds, runs and updates the app for you, with domains and free HTTPS certificates through Traefik. This IceStore version runs as one ZimaOS app: on first start it sets up Docker Swarm, its Postgres database and Traefik by itself, and every install gets its own secret keys.

## Features

- Deploy from GitHub, GitLab, Bitbucket, Gitea, any Git URL or a Docker image
- Builds with Nixpacks, Railpack, Heroku buildpacks or your Dockerfile
- Docker Compose stacks and one-click templates
- Postgres, MySQL, MariaDB, MongoDB, Redis and libSQL databases, with backups to S3
- Domains and Let's Encrypt certificates through Traefik
- Logs, a terminal, resource graphs and deploy notifications
- Teams, roles, an API and a CLI

## How to use

1. Open `http://[ZIMAOS-IP-ADDRESS]:6183` and make the admin account.
2. Make a project, then add an application, a compose stack or a database to it.
3. Pick where the code comes from and press Deploy.
4. Add a domain in the app's Domains tab. On your home network, open the app at `http://<domain>:6184`.

## Before you install

Dokploy takes control of Docker on your ZimaOS: on first start it turns on Docker Swarm and adds a `dokploy-postgres` service and a `dokploy-traefik` container next to the app. Deployed apps are served on port 6184 (http) and 6185 (https), because ZimaOS uses 80 and 443 itself. For domains from the internet, forward ports 80 and 443 on your router to 6184 and 6185. The first start takes two or three minutes. Then open `http://[ZIMAOS-IP-ADDRESS]:6183` and make the admin account.

If a deployed app won't start, open its Advanced tab, go to Cluster Settings and set the Endpoint Spec mode to `dnsrr`; ZimaOS's kernel lacks a feature (IPVS) that Swarm uses by default. Update Dokploy from the IceStore, not with the Update button inside Dokploy. Don't install this next to a Dokploy set up with its own install script.

Uninstalling the app leaves Swarm, `dokploy-postgres`, `dokploy-traefik` and your deployed apps running. To remove them too, run `docker service rm dokploy-postgres`, `docker rm -f dokploy-traefik` and `docker swarm leave --force` on ZimaOS.
