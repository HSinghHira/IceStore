# syntax=docker/dockerfile:1.7
#
# Healthchecks, as upstream ships it, plus one IceStore start script that:
#   - gives every install its own SECRET_KEY and admin password (made on
#     first start, kept in /data) and makes the admin account, since signing
#     up needs email;
#   - uses SQLite in /data, so no database container is needed;
#   - prints the login in a CREDENTIALS box.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM healthchecks/healthchecks:v5.0.3

USER root
COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="healthchecks" \
      org.opencontainers.image.description="Healthchecks on SQLite with a per-install secret key and admin account" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script starts as root (to give hc the folder ZimaOS makes), then runs
# upstream's run.sh as hc, as upstream's image does.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["/opt/healthchecks/run.sh"]
