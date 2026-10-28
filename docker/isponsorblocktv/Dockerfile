# syntax=docker/dockerfile:1.7
#
# iSponsorBlockTV, as upstream ships it, plus a web page for its setup wizard.
# Upstream only has a terminal wizard (`--setup`), which ZimaOS can't open, so
# ttyd shows that same wizard in the browser on port 6129. The start script
# also runs the skipper and restarts it whenever the wizard saves config.json.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/dmunozv04/isponsorblocktv:v2.11.0

RUN apk add --no-cache ttyd

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

# Host networking (so the wizard can find TVs on the network), so the setup
# page listens on the app's own port instead of 8080.
ENV ISPONSORBLOCKTV_SETUP_PORT=6129

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD python3 -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:%s/' % os.environ.get('ISPONSORBLOCKTV_SETUP_PORT', '6129'), timeout=3).read()" || exit 1

LABEL org.opencontainers.image.title="isponsorblocktv" \
      org.opencontainers.image.description="iSponsorBlockTV with its setup wizard in the browser, on port 6129" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /app
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["python3", "-u", "main.pyc"]
