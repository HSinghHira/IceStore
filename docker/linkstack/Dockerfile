# syntax=docker/dockerfile:1.7
#
# LinkStack, as upstream ships it, plus one IceStore start script. Upstream
# keeps the whole app in /htdocs and expects a Docker volume there, which
# Docker fills from the image. A fresh ZimaOS folder mounted there is empty
# and owned by root, so the script copies the app in on first start, gives
# the folder to apache and starts LinkStack as apache.
#
# After the first start the app lives in the data folder, as with upstream's
# volume: update it from LinkStack's own admin panel (Admin > Updates).
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM linkstackorg/linkstack:v4.8.8

USER root
RUN apk add --no-cache setpriv \
 && cp -a /htdocs /opt/linkstack-dist

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="linkstack" \
      org.opencontainers.image.description="LinkStack that fills an empty data folder on first start" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /htdocs
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["docker-entrypoint.sh"]
