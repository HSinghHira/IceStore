# syntax=docker/dockerfile:1.7
#
# Dashy, as upstream ships it, plus one IceStore start script. Upstream keeps
# its config in /app/user-data/conf.yml inside the image; a fresh ZimaOS
# folder mounted there is empty and owned by root, so Dashy would show no
# dashboard and could not save. The script puts the sample conf.yml in place
# on first start, gives the folder to Dashy's user (1000) and starts Dashy as
# that user.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM lissy93/dashy:4.10.0

USER root
RUN apk add --no-cache su-exec \
 && cp /app/user-data/conf.yml /app/conf.sample.yml

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="dashy" \
      org.opencontainers.image.description="Dashy that fills an empty config folder and can save to it" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /app
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/icestore-init"]
CMD ["node", "server.js"]
