# syntax=docker/dockerfile:1.7
#
# __TITLE__ all-in-one. CI runs ./capture-meta.sh first (it fills ./meta).
# To bump a version, change the tag on a FROM line below and rebuild.
#
# 1) One "FROM <image>:<pinned tag> AS img-<service>" line per upstream image.
#    <service> must match the supervisord program name and the run-svc.sh case.
#    capture-meta.sh reads exactly this pattern, so keep it on one line.

FROM __UPSTREAM_IMAGE__:__UPSTREAM_TAG__ AS img-app

# 2) Native services: copy the binary (and its data folder) out of its image.
#    Only do this for statically linked or glibc binaries that run on Debian.
#    Find the path with:  docker run --rm --entrypoint sh <image> -c 'ls -l /usr/local/bin /app'
#
# FROM debian:bookworm-slim AS native-bins
# COPY --from=img-server / /r/server
# RUN set -eu; install -D /r/server/usr/local/bin/server /out/usr/local/bin/server

# 3) The base image: built-in services come from apt.
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d; \
    mkdir -p /etc/postgresql-common; echo 'create_main_cluster = false' > /etc/postgresql-common/createcluster.conf; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
    install -d /usr/share/keyrings; \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt trixie-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        postgresql-16 redis-server nginx supervisor jq util-linux procps openssl tzdata; \
    rm -rf /var/lib/apt/lists/*

# COPY --from=native-bins /out/ /

# 4) Chroot services: the whole upstream filesystem, one folder each.
COPY --from=img-app / /opt/rootfs/app/

COPY meta/ /opt/meta/
COPY aio-init.sh /usr/local/bin/aio-init
COPY run-svc.sh /usr/local/bin/run-svc
COPY supervisord.conf /etc/supervisor/aio.conf
COPY nginx.conf.tpl /etc/nginx/aio.conf.tpl
RUN chmod +x /usr/local/bin/aio-init /usr/local/bin/run-svc

LABEL org.opencontainers.image.title="__APP__" \
      org.opencontainers.image.description="__TITLE__ in a single container" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 8080
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=240s --retries=5 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:8080__HEALTH_PATH__ || exit 1

ENTRYPOINT ["/usr/local/bin/aio-init"]
