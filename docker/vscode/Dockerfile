# syntax=docker/dockerfile:1.7
#
# linuxserver's VS Code desktop image, as upstream ships it, plus one IceStore
# start script that gives every install its own login password (made on
# first start, kept in /config). Nothing else is changed.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM lscr.io/linuxserver/vscode:1.143.1-ls31

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="vscode" \
      org.opencontainers.image.description="VS Code desktop with a per-install login password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script ends with `exec /init`, so s6-overlay still runs as PID 1.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
