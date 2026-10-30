# syntax=docker/dockerfile:1.7
#
# Dokploy, as upstream ships it, plus one IceStore start script that does the
# work of Dokploy's host installer through the Docker socket:
#   - gives every install its own BETTER_AUTH_SECRET and Postgres password
#     (made on first start, kept in /data),
#   - joins Docker Swarm, makes dokploy-network, the dokploy-postgres service
#     and the dokploy-traefik container,
#   - moves Traefik to ports 6184 / 6185, since ZimaOS uses 80 itself.
# Nothing else is changed.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM dokploy/dokploy:v0.30.10

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

# Dokploy reads its secrets from these files. Set here (not in the start
# script) so `docker exec` commands see them too.
ENV POSTGRES_PASSWORD_FILE=/data/.postgres_password \
    BETTER_AUTH_SECRET_FILE=/data/.better_auth_secret \
    RELEASE_TAG=latest

LABEL org.opencontainers.image.title="dokploy" \
      org.opencontainers.image.description="Dokploy for ZimaOS: one container that sets up Swarm, Postgres and Traefik itself" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# tini -g sends stop signals to the start script's Traefik helper too.
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/icestore-init"]
CMD ["sh", "-c", "node -r dotenv/config dist/wait-for-postgres.mjs && node -r dotenv/config dist/migration.mjs && exec node -r dotenv/config dist/server.mjs"]
