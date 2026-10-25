# syntax=docker/dockerfile:1.7
#
# Yuvomi, as upstream ships it, plus one IceStore start script that gives
# every install its own SESSION_SECRET and DB_ENCRYPTION_KEY (made on first
# start, kept in the data folder). Yuvomi refuses to start without a session
# secret, and a key written in the compose file would be the same for everyone.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/ulsklyc/yuvomi:2.79.0

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

# Upstream sets these in its compose file, not in the image. Without DB_PATH
# the database would land in /app, outside the data volume.
ENV NODE_ENV=production \
    DB_PATH=/data/yuvomi.db \
    BACKUP_DIR=/backups \
    MODULES_DIR=/app/modules

LABEL org.opencontainers.image.title="yuvomi" \
      org.opencontainers.image.description="Yuvomi with a per-install session secret and database key" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["node", "server/index.js"]
