# syntax=docker/dockerfile:1.7
#
# Firefly III, as upstream ships it, plus one IceStore start script that:
#   - gives every install its own APP_KEY and STATIC_CRON_TOKEN (made on
#     first start, kept in /var/www/html/storage/database);
#   - uses SQLite, so no database container is needed;
#   - runs Firefly III's daily cron job (recurring transactions, bill
#     reminders) from inside the container, which upstream does with a
#     third container.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM fireflyiii/core:version-6.7.9

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssl util-linux \
 && apt-get clean && rm -rf /var/lib/apt/lists/*
COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="firefly-iii" \
      org.opencontainers.image.description="Firefly III on SQLite with a per-install app key and a built-in cron job" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script starts as root (to give www-data the folders ZimaOS makes),
# then runs upstream's entrypoint as www-data, as upstream's image does.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/init"]
