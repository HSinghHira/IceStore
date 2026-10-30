# syntax=docker/dockerfile:1.7
#
# strava-dawarich-sync, as upstream ships it, plus a setup page on port 8080.
# Upstream's one-time Strava sign-in (`python authorize.py`) asks for input in
# a terminal, which ZimaOS can't open, so the setup page does the same steps
# in the browser with upstream's own code. The sync loop starts once Strava is
# connected and the Dawarich settings are filled in.
#
# Upstream only publishes `latest` and `sha-<commit>` tags. The weekly bumper
# (update-upstream.yml) moves the commit tag below to the one `latest` points at.

FROM ghcr.io/benno93/strava-dawarich-sync:sha-5faa02f

COPY icestore-init.sh /usr/local/bin/icestore-init
COPY setup_page.py /opt/icestore/setup_page.py
RUN chmod +x /usr/local/bin/icestore-init

ENV ICESTORE_SETUP_PORT=8080

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=3).read()" || exit 1

LABEL org.opencontainers.image.title="strava-dawarich-sync" \
      org.opencontainers.image.description="strava-dawarich-sync with a setup page for the Strava sign-in, on port 8080" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /app
ENTRYPOINT ["/usr/local/bin/icestore-init"]
# Upstream's own command (setting ENTRYPOINT clears the inherited CMD).
CMD ["sh", "-c", "while true; do python sync.py; sleep $(( ${SYNC_INTERVAL_MINUTES:-60} * 60 )); done"]
