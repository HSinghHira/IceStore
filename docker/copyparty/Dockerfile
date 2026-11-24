# syntax=docker/dockerfile:1.7
#
# copyparty (the recommended "ac" edition), as upstream ships it, plus one
# IceStore start script. Upstream's default shares /w read-write with
# everyone; on first start the script writes /cfg/copyparty.conf with one
# admin account (a per-install password) and no anonymous access instead.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM copyparty/ac:1.20.28

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="copyparty" \
      org.opencontainers.image.description="copyparty with a per-install admin account" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENV PYTHONUNBUFFERED=1

ENTRYPOINT ["/usr/local/bin/icestore-init"]
