# syntax=docker/dockerfile:1.7
#
# FileBrowser Quantum, as upstream ships it, plus one IceStore start script.
# Upstream has no environment variables for its file sources or cache folder,
# and without a config.yaml it shows its own program folder. The script
# writes a starter config.yaml on first start (your files at /srv, the cache
# in the app folder) and a random admin password, shown in the CREDENTIALS
# box. It runs as root so it can read and write the files ZimaOS owns.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM gtstef/filebrowser:2.0.2-stable

USER root
COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="filebrowser-quantum" \
      org.opencontainers.image.description="FileBrowser Quantum with a starter config and a per-install admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /home/filebrowser
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["./filebrowser"]
