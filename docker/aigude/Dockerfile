# syntax=docker/dockerfile:1.7
#
# AI Gude for IceStore. Upstream publishes release binaries but no image;
# this image is upstream's Dockerfile with the release binary and the same
# static ffmpeg (mise.toml's version), on Alpine instead of distroless so one
# start script can put a starter show in place on the first start.
#
# To update, change AIGUDE_VERSION below (and x-casaos.version in the
# compose file), bump AIO_VERSION in build-aigude.yml and rebuild.

ARG AIGUDE_VERSION=0.1.0

FROM alpine:3.24.4
ARG AIGUDE_VERSION
ARG TARGETARCH

COPY --from=mwader/static-ffmpeg:9.0.2 /ffmpeg /usr/local/bin/ffmpeg
RUN set -eux; \
    apk add --no-cache ca-certificates tzdata su-exec; \
    wget -qO /tmp/aigude.tgz "https://github.com/alex0ptr/aigude/releases/download/v${AIGUDE_VERSION}/aigude_${AIGUDE_VERSION}_linux_${TARGETARCH}.tar.gz"; \
    mkdir -p /tmp/aigude; tar -xzf /tmp/aigude.tgz -C /tmp/aigude; \
    install -m 0755 "$(find /tmp/aigude -type f -name aigude | head -n1)" /usr/local/bin/aigude; \
    rm -rf /tmp/aigude /tmp/aigude.tgz; \
    mkdir -p /usr/share/aigude; \
    wget -qO /usr/share/aigude/starter.toml "https://raw.githubusercontent.com/alex0ptr/aigude/v${AIGUDE_VERSION}/hack/users/demo.toml"; \
    adduser -D -H -u 10001 aigude

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="aigude" \
      org.opencontainers.image.description="AI Gude ${AIGUDE_VERSION} (release binary) with ffmpeg" \
      org.opencontainers.image.version="${AIGUDE_VERSION}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

# Upstream's image settings.
ENV AIGUDE_USERS_DIR=/etc/aigude/users \
    AIGUDE_DATA_DIR=/var/lib/aigude/data \
    AIGUDE_LISTEN_ADDR=0.0.0.0:8080
WORKDIR /etc/aigude
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["serve"]
