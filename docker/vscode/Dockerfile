# syntax=docker/dockerfile:1.7
#
# linuxserver's VS Code desktop image, as upstream ships it, plus one IceStore
# start script that gives every install its own login password (made on
# first start, kept in /config). Nothing else is changed.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM lscr.io/linuxserver/vscode:1.143.1-ls31

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="vscode" \
      org.opencontainers.image.description="VS Code desktop with a per-install login password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script ends with `exec /init`, so s6-overlay still runs as PID 1.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
