# syntax=docker/dockerfile:1.7
#
# slskd, as upstream ships it, plus one IceStore start script that gives
# every install its own web UI password and JWT key (made on first start,
# kept in /app), instead of upstream's default login slskd / slskd, and
# prints the login in a CREDENTIALS box.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM slskd/slskd:0.26.2

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="slskd" \
      org.opencontainers.image.description="slskd with a per-install web UI password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script ends with upstream's /entrypoint.sh (PUID/PGID handling).
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/icestore-init"]
CMD ["./slskd"]
