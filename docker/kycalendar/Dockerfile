# syntax=docker/dockerfile:1.7
#
# KyCalendar, as upstream ships it, plus one IceStore start script that gives
# every install its own session secret (made on first start, kept in the data
# folder), fits the http/cookie settings to the address and prints the first
# admin password in the CREDENTIALS banner. Upstream's image is amd64 only.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/busnes-app/kycalendar:0.6.1.3

# The start script runs as root (ZimaOS makes the bind folders as root) and
# drops to 10001:10001, upstream's user, with setpriv.
USER 0:0
RUN apk add --no-cache setpriv

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY kycalendar /usr/local/bin/kycalendar
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/kycalendar /usr/local/lib/icestore/credentials.sh

# One SQLite install in production mode, with upstream compose's paths.
ENV KY_ENV=production \
    KY_APP_NAME=KyCalendar \
    KY_DB_DRIVER=sqlite \
    KY_DATA_DIR=/app/data \
    KYCALENDAR_BACKUP_DIR=/app/backups

LABEL org.opencontainers.image.title="kycalendar" \
      org.opencontainers.image.description="KyCalendar with a per-install session secret for IceStore" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD []
