# syntax=docker/dockerfile:1.7
#
# wastebin, as upstream ships it (a FROM scratch image), plus busybox for a
# shell and one IceStore start script that gives every install its own
# cookie signing key and password salt (made on first start, kept in /data).
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM quxfoo/wastebin:3.9.0

USER 0:0
COPY --from=busybox:1.38.0-musl /bin/busybox /bin/busybox
RUN ["/bin/busybox", "--install", "-s", "/bin"]

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="wastebin" \
      org.opencontainers.image.description="wastebin with a per-install signing key and password salt" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/app/wastebin"]
