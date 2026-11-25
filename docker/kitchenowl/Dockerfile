# syntax=docker/dockerfile:1.7
#
# KitchenOwl, as upstream ships it, plus one IceStore start script that gives
# every install its own secrets (made on first start, kept in /data).
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM tombursch/kitchenowl:v0.8.1

# uWSGI's default 4 KB request buffer rejects requests with big headers (large
# cookies, shared by every app on this IP), so the app returned no response.
ENV UWSGI_BUFFER_SIZE=65535

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="kitchenowl" \
      org.opencontainers.image.description="KitchenOwl with per-install secrets" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["--ini", "wsgi.ini:web", "--gevent", "200", "--max-fd", "1048576"]
