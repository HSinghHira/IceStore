# syntax=docker/dockerfile:1.7
#
# Rclone, as upstream ships it, plus one IceStore start script that gives
# every install its own login (made on first start, kept in /config) and
# starts the built-in web GUI (rclone gui) on all addresses.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM rclone/rclone:1.76.0

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="rclone" \
      org.opencontainers.image.description="Rclone web GUI with a per-install login" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# rclone.conf is /config/rclone/rclone.conf (upstream's XDG_CONFIG_HOME);
# keep the cache there too so it survives updates.
ENV XDG_CACHE_HOME=/config/cache

ENTRYPOINT ["/usr/local/bin/icestore-init"]
