# syntax=docker/dockerfile:1.7
#
# Disk Monitor, as upstream ships it, plus one IceStore start script that gives
# every install its own session secret and (when DISK_MONITOR_PASSWORD is blank)
# its own login password, both kept in /app/cache. The app listens on 6170
# instead of 8999, because it runs with host networking.
#
# The weekly bumper (update-upstream.yml) moves the tag below.

FROM ghcr.io/isanto1306/disk-monitor:0.32.104

COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

ENV DISK_MONITOR_PORT=6170

# Upstream's healthcheck asks port 8999; ask the port the app really uses.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD python -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:%s/api/auth/status' % os.environ.get('DISK_MONITOR_PORT', '6170'), timeout=3).read()" || exit 1

LABEL org.opencontainers.image.title="disk-monitor" \
      org.opencontainers.image.description="Disk Monitor with a per-install session secret and password, on port 6170" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["uvicorn", "entrypoint_header_stable:app", "--host", "0.0.0.0", "--port", "6170", "--no-server-header", "--no-access-log"]
