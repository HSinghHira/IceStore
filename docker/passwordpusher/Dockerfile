# syntax=docker/dockerfile:1.7
#
# Password Pusher, as upstream ships it, plus one IceStore start script.
# Upstream needs SECRET_KEY_BASE and otherwise makes a new one on every
# start (everyone is signed out and encrypted pushes may not open). The
# script makes one per install, keeps it in the storage folder and passes
# it as SECRET_KEY_BASE_FILE. It also gives the storage folder, which
# ZimaOS makes as root, to the app's user before starting it as that user.
#
# The daily bumper (update-upstream.yml) moves the tag below.

FROM pglombardo/pwpush:2.17.2

USER root
RUN apk add --no-cache su-exec
COPY icestore-init.sh /usr/local/bin/icestore-init
RUN chmod +x /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="passwordpusher" \
      org.opencontainers.image.description="Password Pusher with a per-install SECRET_KEY_BASE" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /opt/PasswordPusher
ENTRYPOINT ["/usr/local/bin/icestore-init"]
