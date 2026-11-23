# syntax=docker/dockerfile:1.7
#
# Vikunja, as upstream ships it, plus one IceStore start script that gives
# every install its own service secret (made on first start, kept in /data)
# and keeps the SQLite database and uploads in /data. Upstream's image is
# FROM scratch, so a static busybox is added for the script and the
# healthcheck.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM vikunja/vikunja:2.8.0

# Numeric: the scratch image has no /etc/passwd to look "root" up in.
USER 0:0
COPY --from=busybox:1.38.0-musl /bin/busybox /bin/busybox
RUN ["/bin/busybox", "mkdir", "-p", "/usr/local/bin", "/usr/local/lib/icestore", "/bin", "/usr/bin"]
RUN ["/bin/busybox", "--install", "-s", "/usr/local/bin"]
RUN ["/bin/busybox", "sh", "-c", "[ -e /bin/sh ] || ln -s /bin/busybox /bin/sh"]

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN ["/bin/busybox", "chmod", "+x", "/usr/local/bin/icestore-init", "/usr/local/lib/icestore/credentials.sh"]

LABEL org.opencontainers.image.title="vikunja" \
      org.opencontainers.image.description="Vikunja with a per-install service secret and its data in /data" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# Upstream points the database at /db; keep everything in the one /data folder.
ENV VIKUNJA_DATABASE_PATH=/data/vikunja.db \
    VIKUNJA_FILES_BASEPATH=/data/files
# Runs as root so it can write the bind-mounted data folder ZimaOS makes.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
