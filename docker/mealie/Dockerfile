# syntax=docker/dockerfile:1.7
#
# Mealie, as upstream ships it, plus one IceStore start script that replaces
# the published default admin password (changeme@example.com / MyPassword)
# with one made for this install, and prints the login in a CREDENTIALS box.
# Mealie makes its own secret keys; SQLite is the database.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/mealie-recipes/mealie:v3.31.0

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY mealie-admin.py /usr/local/lib/icestore/mealie-admin.py
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh \
 && chmod 644 /usr/local/lib/icestore/mealie-admin.py

LABEL org.opencontainers.image.title="mealie" \
      org.opencontainers.image.description="Mealie with a per-install admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script ends with `exec /app/run.sh`, upstream's entrypoint.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
