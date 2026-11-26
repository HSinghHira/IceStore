# syntax=docker/dockerfile:1.7
#
# NoteDiscovery, as upstream ships it, plus one IceStore start script that
# turns the login on with this install's own password and session secret
# (made on first start, kept in /app/data). Upstream ships with the login off
# and a default password of admin.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/gamosoft/notediscovery:0.36.1

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="notediscovery" \
      org.opencontainers.image.description="NoteDiscovery with the login on and a per-install password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /app
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/bin/sh", "-c", "exec uvicorn backend.main:app --host 0.0.0.0 --port $PORT --timeout-graceful-shutdown 2"]
