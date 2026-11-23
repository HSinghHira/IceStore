# syntax=docker/dockerfile:1.7
#
# Gotify, as upstream ships it, plus one IceStore start script that gives
# every install its own admin password on first start (upstream's default
# is admin/admin) and prints it in the CREDENTIALS box.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM gotify/server:3.1.1

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="gotify" \
      org.opencontainers.image.description="Gotify with a per-install admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /app
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["./gotify-app", "serve"]
