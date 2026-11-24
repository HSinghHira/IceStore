# syntax=docker/dockerfile:1.7
#
# Dufs, as upstream ships it, plus one IceStore start script that gives every
# install its own login (made on first start, kept in /config). Upstream's
# image is FROM scratch with no shell, so a static busybox is added for the
# script and the healthcheck.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM sigoden/dufs:v0.47.0

COPY --from=busybox:1.38.0-musl /bin/busybox /bin/busybox
RUN ["/bin/busybox", "mkdir", "-p", "/usr/local/bin", "/usr/local/lib/icestore", "/tmp"]
RUN ["/bin/busybox", "--install", "-s", "/usr/local/bin"]
RUN ["/bin/busybox", "sh", "-c", "[ -e /bin/sh ] || ln -s /bin/busybox /bin/sh; chmod 1777 /tmp"]

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN ["/bin/busybox", "chmod", "+x", "/usr/local/bin/icestore-init", "/usr/local/lib/icestore/credentials.sh"]

LABEL org.opencontainers.image.title="dufs" \
      org.opencontainers.image.description="Dufs file server with a per-install login" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    AIO_CRED_FILE=/tmp/icestore-credentials
# Runs as root (scratch has no /etc/passwd, so no USER line) so it can read
# and write every folder under /DATA, like the ZimaOS Files app.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
