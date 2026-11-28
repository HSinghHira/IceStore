# syntax=docker/dockerfile:1.7
#
# DailyTxT, as upstream ships it, plus one IceStore start script that gives
# every install its own SECRET_TOKEN (upstream makes a new one on every
# start, which signs everyone out) and an admin password, both kept in /data.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM phitux/dailytxt:2.7.2

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="dailytxt" \
      org.opencontainers.image.description="DailyTxT with a per-install secret token and admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/entrypoint.sh"]
