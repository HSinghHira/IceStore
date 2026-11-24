# syntax=docker/dockerfile:1.7
#
# Glance, as upstream ships it, plus one IceStore start script that writes a
# starter glance.yml on first start (Glance will not start without one), so
# the dashboard opens right after install.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM glanceapp/glance:v0.8.8

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY glance.yml /usr/local/share/icestore/glance.yml
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="glance" \
      org.opencontainers.image.description="Glance dashboard with a starter config" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
