# syntax=docker/dockerfile:1.7
#
# Radicale (tomsquest/docker-radicale), as upstream ships it, plus one
# IceStore start script that turns the login on with a password made for
# each install (kept in /data).
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM tomsquest/docker-radicale:3.9.2.0

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="radicale" \
      org.opencontainers.image.description="Radicale with a per-install login" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/venv/bin/radicale", "--config", "/config/config"]
