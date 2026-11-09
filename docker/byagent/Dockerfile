# syntax=docker/dockerfile:1.7
#
# byagent, as upstream ships it, plus one IceStore start script that gives
# every install its own admin API token and signing key (made on first start,
# kept in the data folder). Upstream's image is distroless (no shell), so a
# static busybox is added for the script and the healthcheck.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/anup-a/byagent:v0.9.0

USER root
COPY --from=busybox:1.38.0-musl /bin/busybox /bin/busybox
RUN ["/bin/busybox", "--install", "-s", "/bin"]

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="byagent" \
      org.opencontainers.image.description="byagent with a per-install admin token and signing key" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# Runs as root so it can write the bind-mounted data folder ZimaOS makes.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
