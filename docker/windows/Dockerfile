# syntax=docker/dockerfile:1.7
#
# dockur's Windows image, as upstream ships it, plus one IceStore start script
# that gives every install its own Windows password (made on first start,
# kept in /storage) instead of upstream's shared default "admin". Nothing
# else is changed.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM dockurr/windows:6.06

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="windows" \
      org.opencontainers.image.description="Windows in a container with a per-install password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# Upstream runs tini -s /run/entry.sh; the script ends with exec /run/entry.sh,
# so tini stays PID 1 and stops QEMU cleanly.
ENTRYPOINT ["/usr/bin/tini", "-s", "/usr/local/bin/icestore-init"]
