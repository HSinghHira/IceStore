# syntax=docker/dockerfile:1.7
#
# gonic, as upstream ships it, plus sqlite3 and one IceStore start script
# that replaces gonic's default admin/admin login with a password made for
# each install (kept in /data).
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM sentriz/gonic:v0.23.0

RUN apk add --no-cache sqlite

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

# Playlists live in the data folder instead of a separate /playlists.
ENV GONIC_PLAYLISTS_PATH=/data/playlists

LABEL org.opencontainers.image.title="gonic" \
      org.opencontainers.image.description="gonic with a per-install admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/icestore-init"]
CMD ["gonic"]
