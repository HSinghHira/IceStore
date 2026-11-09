# syntax=docker/dockerfile:1.7
#
# Trackhop, as upstream ships it, plus one IceStore start script that gives
# every install its own SONGPORT_PASSWORD (made on first start, kept in the
# data folder). Upstream's image has no shell, so a static busybox is added
# for the script and the healthcheck.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/xlollx/trackhop:1.8.1

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

LABEL org.opencontainers.image.title="trackhop" \
      org.opencontainers.image.description="Trackhop with a per-install password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/java/openjdk/bin
# Runs as root so it can write the bind-mounted data folder ZimaOS makes.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
