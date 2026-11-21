#!/bin/bash
# IceStore start script for Gramps Web. Runs as root, once per start:
#
#   - Every data folder upstream keeps in a separate volume lives under
#     /data: the family tree, users, media, search index, caches, the Flask
#     secret (upstream's entrypoint makes it in /app/secret, linked to
#     /data/secret) and Redis.
#   - Celery and the rate limiter use the Redis inside this container.
#   - GRAMPSWEB_BASE_URL: blank means http://localhost:6789 (used in email
#     links).
#   - Every other blank variable is dropped, so Gramps Web uses its default
#     (ZimaOS passes settings left empty as empty strings).
#
# Then supervisord runs Redis, Gramps Web and its Celery worker.
set -euo pipefail

DATA=/data
LOG_TAG=icestore
. /usr/local/lib/icestore/lib.sh

mkdir -p "$DATA"/{grampsdb,users,media,indexdir,thumbnail_cache,cache,secret,redis}

# Upstream's entrypoint writes the Flask secret to /app/secret/secret.
if [ ! -L /app/secret ]; then
  rm -rf /app/secret
  ln -s "$DATA/secret" /app/secret
fi

for v in $(compgen -e); do
  [ -n "${!v}" ] || unset "$v" 2>/dev/null || true
done

export GRAMPS_DATABASE_PATH=$DATA/grampsdb
export GRAMPSWEB_USER_DB_URI=sqlite:///$DATA/users/users.sqlite
export GRAMPSWEB_MEDIA_BASE_DIR=$DATA/media
export GRAMPSWEB_SEARCH_INDEX_DB_URI=sqlite:///$DATA/indexdir/search_index.db
export GRAMPSWEB_THUMBNAIL_CACHE_CONFIG__CACHE_DIR=$DATA/thumbnail_cache
export GRAMPSWEB_REQUEST_CACHE_CONFIG__CACHE_DIR=$DATA/cache/request_cache
export GRAMPSWEB_PERSISTENT_CACHE_CONFIG__CACHE_DIR=$DATA/cache/persistent_cache
export GRAMPSWEB_REPORT_DIR=$DATA/cache/reports
export GRAMPSWEB_EXPORT_DIR=$DATA/cache/export
export GRAMPSWEB_CELERY_CONFIG__broker_url=redis://127.0.0.1:6379/0
export GRAMPSWEB_CELERY_CONFIG__result_backend=redis://127.0.0.1:6379/0
export GRAMPSWEB_RATELIMIT_STORAGE_URI=redis://127.0.0.1:6379/1
[ -n "${GRAMPSWEB_TREE:-}" ] || GRAMPSWEB_TREE="Gramps Web"
[ -n "${GRAMPSWEB_BASE_URL:-}" ] || GRAMPSWEB_BASE_URL=http://localhost:6789
[ -n "${GUNICORN_NUM_WORKERS:-}" ] || GUNICORN_NUM_WORKERS=2
[ -n "${GUNICORN_TIMEOUT:-}" ] || GUNICORN_TIMEOUT=120
[ -n "${CELERY_CONCURRENCY:-}" ] || CELERY_CONCURRENCY=2
export GRAMPSWEB_TREE GRAMPSWEB_BASE_URL GUNICORN_NUM_WORKERS GUNICORN_TIMEOUT CELERY_CONCURRENCY

chown -R redis:redis "$DATA/redis"

# ---- CREDENTIALS banner (docker/_common) ----
cred_reset
cred_add URL "http://<your ZimaOS IP>:6789"
cred_note "No account yet: the first page asks you to make the owner account."

exec /usr/bin/supervisord -n -c /etc/supervisor/icestore.conf
