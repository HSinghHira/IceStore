# syntax=docker/dockerfile:1.7
#
# HedgeDoc, as upstream ships it, plus one IceStore start script that gives
# every install its own session secret (made on first start, kept in /data)
# and keeps the SQLite database in /data. Nothing else is changed.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM quay.io/hedgedoc/hedgedoc:1.12.3

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="hedgedoc" \
      org.opencontainers.image.description="HedgeDoc with SQLite in /data and a per-install session secret" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script ends with `exec docker-entrypoint.sh "$@"`; CMD stays upstream's.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["node", "app.js"]
