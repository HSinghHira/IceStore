# syntax=docker/dockerfile:1.7
#
# RomSeek for IceStore. Upstream runs its one Python file (no dependencies) on
# the stock python:3.12-alpine image with the file mounted in; it publishes
# no image and no releases, so this image carries the file from one pinned
# commit of github.com/Evident-Dev/romseek.
#
# To update, change ROMSEEK_REF below (and x-casaos.version in the compose
# file), bump AIO_VERSION in build-romseek.yml and rebuild.

ARG ROMSEEK_REF=ea4f9091ca723347e798abdf3c3019154d385bf8

# auto-update: hold
FROM python:3.12.16-alpine
ARG ROMSEEK_REF

ADD https://raw.githubusercontent.com/Evident-Dev/romseek/${ROMSEEK_REF}/romseek.py /app/romseek.py
ADD https://raw.githubusercontent.com/Evident-Dev/romseek/${ROMSEEK_REF}/index.html /app/index.html
ADD https://raw.githubusercontent.com/Evident-Dev/romseek/${ROMSEEK_REF}/logo.svg /app/logo.svg
RUN chmod a+r /app/* && mkdir -p /state

LABEL org.opencontainers.image.title="romseek" \
      org.opencontainers.image.description="RomSeek (commit ${ROMSEEK_REF}) on python:3.12-alpine" \
      org.opencontainers.image.version="${ROMSEEK_REF}" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

WORKDIR /app
ENV STATE_DIR=/state PORT=8000
EXPOSE 8000
ENTRYPOINT ["python3", "-u", "/app/romseek.py"]
