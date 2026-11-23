# syntax=docker/dockerfile:1.7
#
# Warracker, as upstream ships it, plus:
#   - PostgreSQL (Debian trixie's package) inside the same container, so
#     the database upstream runs as a second container is built in;
#   - one IceStore start script that makes this install's database password
#     on first start (kept in /data) and starts PostgreSQL before upstream's
#     own entrypoint runs its migrations.
#
# Warracker makes its own SECRET_KEY (kept in /data/uploads/.secret_key) and
# the first account you register becomes the admin.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/sassanix/warracker/main:1.0.6

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-17 openssl \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY handoff.sh /usr/local/bin/icestore-handoff
COPY postgres.conf /etc/supervisor/conf.d/postgres.conf
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/bin/icestore-handoff /usr/local/lib/icestore/credentials.sh \
 && printf '\n[include]\nfiles = /etc/supervisor/conf.d/postgres.conf\n' >> /etc/supervisor/conf.d/supervisord.conf

LABEL org.opencontainers.image.title="warracker" \
      org.opencontainers.image.description="Warracker with PostgreSQL inside and a per-install database password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -f http://localhost/api/health || exit 1

# icestore-init starts PostgreSQL, then runs upstream's /app/entrypoint.sh
# (migrations, nginx config), which ends with icestore-handoff: that stops
# the temporary PostgreSQL and starts supervisord, which runs PostgreSQL,
# nginx, gunicorn and cron.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD []
