# syntax=docker/dockerfile:1.7
#
# Meilisearch, as upstream ships it, plus one IceStore start script that gives
# every install its own master key (made on first start, kept in the data
# folder).
#
# The daily bumper (update-upstream.yml) moves the tag below. MEILI_UPGRADE_DB
# lets each new version open the database the previous one wrote, instead of
# refusing to start until you export and import a dump.

FROM getmeili/meilisearch:v1.58.0

COPY icestore-init.sh /usr/local/bin/icestore-init
# Shared helpers and the CREDENTIALS banner (docker/_common; built with
# --build-context common=docker/_common).
COPY --from=common lib.sh credentials.sh /usr/local/lib/icestore/
RUN chmod +x /usr/local/bin/icestore-init /usr/local/lib/icestore/credentials.sh

LABEL org.opencontainers.image.title="meilisearch" \
      org.opencontainers.image.description="Meilisearch with a per-install master key" \
      org.opencontainers.image.source="https://github.com/HSinghHira/IceStore"

ENV MEILI_UPGRADE_DB=true

ENTRYPOINT ["tini", "--", "/usr/local/bin/icestore-init"]
CMD ["/bin/meilisearch"]
