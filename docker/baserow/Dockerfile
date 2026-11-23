# syntax=docker/dockerfile:1.7
#
# Baserow's own all-in-one image (PostgreSQL, Redis, Caddy, backend, web
# frontend and workers), as upstream ships it, plus one IceStore start script
# that handles the [ZIMAOS-IP-ADDRESS] placeholder in BASEROW_PUBLIC_URL and
# prints the address in a CREDENTIALS box. Upstream makes the secrets itself.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM baserow/baserow:2.4.3

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="baserow" \
      org.opencontainers.image.description="Baserow all-in-one with IceStore's address placeholder handling" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script ends with `exec /baserow.sh "$@"`; CMD stays upstream's.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["start"]
