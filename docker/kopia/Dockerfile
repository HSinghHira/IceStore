# syntax=docker/dockerfile:1.7
#
# Kopia, as upstream ships it, plus one IceStore start script that gives every
# install its own web UI password (made on first start, kept in /app/config)
# and starts the server with the web UI.
#
# The daily bumper (update-upstream.yml) moves the tag below. keep-major keeps
# it on 0.x: upstream also pushes nightly builds named like 20261110.0.231742.

# auto-update: keep-major
FROM kopia/kopia:0.23.1

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="kopia" \
      org.opencontainers.image.description="Kopia backup server with a per-install web UI password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The repository password typed in the web UI is saved in /app/config, so the
# server opens the repository again by itself after a restart.
ENV KOPIA_PERSIST_CREDENTIALS_ON_CONNECT=true

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["server", "start", "--insecure", "--disable-csrf-token-checks", "--address=0.0.0.0:51515"]
