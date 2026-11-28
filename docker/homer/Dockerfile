# syntax=docker/dockerfile:1.7
#
# Homer, as upstream ships it, plus one IceStore start script. ZimaOS makes
# the assets bind folder as root, but Homer runs as the lighttpd user (UID
# 1000) and could not copy its example config there. Running the container
# as root instead broke lighttpd's access log (/dev/fd/3, owned by root).
# The start script runs as root, gives the assets folder and the log pipes
# to the lighttpd user, then starts upstream's entrypoint as that user.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM b4bz/homer:v26.11.4

USER root
RUN apk add --no-cache su-exec

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers (docker/_common; built with --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="homer" \
      org.opencontainers.image.description="Homer with an assets folder it can write to" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/bin/sh", "/entrypoint.sh"]
