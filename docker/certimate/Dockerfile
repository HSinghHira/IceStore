# syntax=docker/dockerfile:1.7
#
# Certimate, as upstream ships it, plus one IceStore start script that gives
# every install its own first admin password (made on first start, kept in
# /app/pb_data) instead of upstream's default admin@certimate.fun /
# 1234567890, and prints the login in a CREDENTIALS box.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM certimate/certimate:v0.4.38

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="certimate" \
      org.opencontainers.image.description="Certimate with a per-install admin password" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /app
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["./certimate", "serve", "--http", "0.0.0.0:8090"]
