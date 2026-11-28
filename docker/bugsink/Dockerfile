# syntax=docker/dockerfile:1.7
#
# Bugsink, as upstream ships it, plus one IceStore start script that gives
# every install its own SECRET_KEY and first admin account (kept in /data),
# gives /data to the bugsink user (ZimaOS makes it as root) and works out
# ALLOWED_HOSTS from BASE_URL.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM bugsink/bugsink:2.7.1

USER root
COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="bugsink" \
      org.opencontainers.image.description="Bugsink with a per-install secret key and admin login" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
# Upstream's own start command (setting ENTRYPOINT clears the inherited CMD).
CMD [ "monofy", "bugsink-show-version", "&&", "bugsink-manage", "check", "--deploy", "--fail-level", "WARNING", "&&", "bugsink-manage", "migrate", "snappea", "--database=snappea", "&&", "bugsink-manage", "migrate", "&&", "bugsink-manage", "prestart", "&&", "gunicorn", "--config", "bugsink/gunicorn.docker.conf.py", "--bind=0.0.0.0:$PORT", "--access-logfile", "-", "bugsink.wsgi", "|||", "bugsink-runsnappea"]
