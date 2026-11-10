# syntax=docker/dockerfile:1.7
#
# CartVibe, as upstream ships it (the API and its nginx), plus:
#   - Valkey from Debian, in place of upstream's separate valkey service
#     (background jobs: AI receipt reads, clean-up), on 127.0.0.1 only;
#   - one IceStore start script that makes this install's SECRET_KEY and
#     ENCRYPTION_KEY on first start and keeps them in the data folder.
#
# Upstream tags every build sha-<commit>; the weekly bumper
# (update-upstream.yml) moves the tag below to the one `latest` points at.

FROM ghcr.io/wouekk/cartvibe:sha-591dc65

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends valkey-server; \
    rm -rf /var/lib/apt/lists/*

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="cartvibe" \
      org.opencontainers.image.description="CartVibe with Valkey inside and per-install keys" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
