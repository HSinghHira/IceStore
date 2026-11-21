# syntax=docker/dockerfile:1.7
#
# Homarr, as upstream ships it, plus one IceStore start script that gives
# every install its own SECRET_ENCRYPTION_KEY (made on first start, kept in
# /appdata), which Homarr needs and does not make itself.
#
# Homarr asks for the first admin account on its onboarding page.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/homarr-labs/homarr:v2.14.0

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="homarr" \
      org.opencontainers.image.description="Homarr with a per-install encryption key" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# The script ends with upstream's entrypoint and run.sh, unchanged.
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["sh", "run.sh"]
