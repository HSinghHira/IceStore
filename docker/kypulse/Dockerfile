# syntax=docker/dockerfile:1.7
#
# KyPulse, as upstream ships it, plus one IceStore start script that makes the
# bind folders private (KyPulse refuses group- or other-writable parents of
# its setup socket), drops blank settings (a blank true/false stops it), warns
# when the address isn't https and prints the first admin password in the
# CREDENTIALS banner. Upstream's image is amd64 only.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/busnes-app/kypulse-server:0.6.1.2

# The start script runs as root (ZimaOS makes the bind folders as root) and
# drops to 10001:10001, upstream's user, with setpriv.
USER 0:0
RUN apk add --no-cache setpriv

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY kypulse /usr/local/bin/kypulse
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/kypulse /usr/local/lib/icestore/credentials.sh

# One SQLite install in production mode, with upstream compose's paths.
ENV KYPULSE_ENV=production \
    KYPULSE_APP_NAME=kyPulse \
    KYPULSE_DB_DRIVER=sqlite \
    KYPULSE_DATA_DIR=/app/data \
    KYPULSE_AUDIT_KEY_FILE=/app/secrets/audit.key \
    KYPULSE_BACKUP_DIR=/app/backups

LABEL org.opencontainers.image.title="kypulse" \
      org.opencontainers.image.description="KyPulse for IceStore" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD []
