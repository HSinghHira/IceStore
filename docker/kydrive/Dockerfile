# syntax=docker/dockerfile:1.7
#
# KyDrive, as upstream ships it, plus one IceStore start script that gives
# every install its own session secret and SCIM token (made on first start,
# kept in the data folder), fits the cookie setting to the address, sets up
# the file backup repository and prints the first admin password in the
# CREDENTIALS banner. Upstream's image is amd64 only.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/busnes-app/kydrive-server:0.6.1.2

# The start script runs as root (ZimaOS makes the bind folders as root) and
# drops to 1000:1000, upstream's user, with setpriv.
USER 0:0
RUN apk add --no-cache setpriv

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY kydrive /usr/local/bin/kydrive
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/kydrive /usr/local/lib/icestore/credentials.sh

# Upstream's compose sets these; one SQLite install in production mode.
ENV KY_ENV=production \
    KY_APP_NAME=KyDrive \
    KY_DB_DRIVER=sqlite \
    KY_DATA_DIR=/app/data \
    KY_BACKUP_DIR=/app/backups \
    KYDRIVE_BULK_BACKUP_REPOSITORY=/app/bulk

LABEL org.opencontainers.image.title="kydrive" \
      org.opencontainers.image.description="KyDrive with per-install secrets for IceStore" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD []
