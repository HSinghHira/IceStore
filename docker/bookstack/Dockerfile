# syntax=docker/dockerfile:1.7
#
# linuxserver's BookStack image, as upstream ships it, plus:
#   - MariaDB (Alpine's package) as one more s6 service on 127.0.0.1, so the
#     database upstream runs as a second container lives in the same one;
#   - a wait step so BookStack's migrations only run once MariaDB is up;
#   - one IceStore start script that gives every install its own APP_KEY,
#     database password and admin password (made on first start, kept in
#     /config), and a one-shot that puts that password on admin@admin.com;
#   - the login in a CREDENTIALS box in the logs.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM lscr.io/linuxserver/bookstack:v26.09.3-ls301

RUN apk add --no-cache mariadb

# s6 services (see each run script):
#   svc-mariadb          -> after init-nginx-end, before BookStack's init
#   init-icestore-dbwait -> waits for MariaDB; init-bookstack-config waits for it
#   init-icestore-admin  -> after init-bookstack-config (the migrations)
COPY s6/ /etc/s6-overlay/s6-rc.d/
RUN chmod +x /etc/s6-overlay/s6-rc.d/svc-mariadb/run \
             /etc/s6-overlay/s6-rc.d/init-icestore-dbwait/run \
             /etc/s6-overlay/s6-rc.d/init-icestore-admin/run \
 && touch /etc/s6-overlay/s6-rc.d/user/contents.d/svc-mariadb \
          /etc/s6-overlay/s6-rc.d/user/contents.d/init-icestore-dbwait \
          /etc/s6-overlay/s6-rc.d/user/contents.d/init-icestore-admin \
          /etc/s6-overlay/s6-rc.d/init-bookstack-config/dependencies.d/init-icestore-dbwait \
          /etc/s6-overlay/s6-rc.d/init-config-end/dependencies.d/init-icestore-admin

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY bookstack-admin.php /usr/local/lib/icestore/bookstack-admin.php
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="bookstack" \
      org.opencontainers.image.description="BookStack with MariaDB inside and a per-install app key and admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script ends with `exec /init`, so s6-overlay still runs as PID 1.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
