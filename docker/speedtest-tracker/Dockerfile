# syntax=docker/dockerfile:1.7
#
# linuxserver's Speedtest Tracker image, as upstream ships it, plus one
# IceStore start script that gives every install its own APP_KEY and first
# admin password (made on first start, kept in /config) and prints the login
# in a CREDENTIALS box. SQLite is the database.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM lscr.io/linuxserver/speedtest-tracker:v1.15.1-ls183

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="speedtest-tracker" \
      org.opencontainers.image.description="Speedtest Tracker with a per-install app key and admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script ends with `exec /init`, so s6-overlay still runs as PID 1.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
