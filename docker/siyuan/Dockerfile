# syntax=docker/dockerfile:1.7
#
# SiYuan, as upstream ships it, plus one IceStore start script that gives
# every install its own access code (the lock screen password), made on
# first start and kept in the workspace folder.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM b3log/siyuan:v3.8.11

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="siyuan" \
      org.opencontainers.image.description="SiYuan with a per-install access code" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENV SIYUAN_WORKSPACE_PATH=/siyuan/workspace

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["serve"]
