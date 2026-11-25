# syntax=docker/dockerfile:1.7
#
# Gatus, as upstream ships it, plus one IceStore start script that gives
# every install its own secrets (made on first start, kept in /config).
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/twin/gatus:v5.38.0
# Upstream's image has no shell; a static busybox runs the start script.
COPY --from=busybox:1.38.0-musl /bin/busybox /bin/busybox
RUN ["/bin/busybox", "mkdir", "-p", "/usr/local/bin", "/usr/local/lib/icestore", "/tmp", "/run"]
RUN ["/bin/busybox", "--install", "-s", "/usr/local/bin"]
RUN ["/bin/busybox", "sh", "-c", "[ -e /bin/sh ] || ln -s /bin/busybox /bin/sh; chmod 1777 /tmp"]
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/app

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh
COPY config.yaml /usr/local/share/icestore/config.yaml

LABEL org.opencontainers.image.title="gatus" \
      org.opencontainers.image.description="Gatus with a starter config" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]

