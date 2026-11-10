# syntax=docker/dockerfile:1.7
#
# tdeemon, as upstream ships it, plus one IceStore start script that makes
# this install's TDEEMON_SECRET_KEY on first start and creates the first admin
# (upstream does that with `tdeemon user create --admin`). Upstream's image is
# distroless, so a static busybox is added for the script.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/tdeemon/tdeemon:1.3.0

USER root
COPY --from=busybox:1.38.0-musl /bin/busybox /bin/busybox
RUN ["/bin/busybox", "mkdir", "-p", "/usr/local/bin", "/usr/local/lib/icestore"]
RUN ["/bin/busybox", "--install", "-s", "/usr/local/bin"]
RUN ["/bin/busybox", "sh", "-c", "[ -e /bin/sh ] || ln -s /bin/busybox /bin/sh"]

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN ["/bin/busybox", "chmod", "+x", "/usr/local/bin/icestore-init", "/usr/local/lib/icestore/credentials.sh"]

LABEL org.opencontainers.image.title="tdeemon" \
      org.opencontainers.image.description="tdeemon with a per-install secret key and first admin" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# Runs as root so it can write the bind-mounted data folder ZimaOS makes.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
