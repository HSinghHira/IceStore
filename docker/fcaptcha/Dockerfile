FROM ghcr.io/webdecoy/fcaptcha:1.52.0

USER 0:0
RUN apk add --no-cache su-exec
COPY --chmod=0755 icestore-init.sh /usr/local/bin/icestore-init

LABEL org.opencontainers.image.title="fcaptcha" \
      org.opencontainers.image.description="FCaptcha with persistent per-install keys" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENTRYPOINT ["/usr/local/bin/icestore-init"]
CMD ["./fcaptcha-server"]
