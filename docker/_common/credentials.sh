#!/bin/bash
# Prints the CREDENTIALS banner on every boot, once the app answers, so it is
# the last thing in the log. supervisord starts it after every other service.
#   Usage: credentials.sh [URL to wait for]   (default http://127.0.0.1:8080/)
# Reads the lines aio-init.sh wrote with cred_add / cred_note.
set -uo pipefail

CRED_FILE=${AIO_CRED_FILE:-/run/icestore/credentials}
url=${1:-http://127.0.0.1:8080/}
deadline=$((SECONDS + ${CRED_WAIT_SECONDS:-600}))
WIDTH=44

[ -s "$CRED_FILE" ] || exit 0

ready=1
until curl -fsS -o /dev/null -m 5 "$url" 2>/dev/null; do
  [ "$SECONDS" -lt "$deadline" ] || { ready=0; break; }
  sleep 3
done

hashes() { local s; printf -v s '%*s' "$1" ''; printf '%s' "${s// /#}"; }
rule() { hashes "$WIDTH"; echo; }
title() {
  local t=" $1 " left
  left=$(( (WIDTH - ${#t}) / 2 ))
  echo "$(hashes "$left")$t$(hashes $(( WIDTH - ${#t} - left )))"
}

pad=0
while IFS=$'\t' read -r kind label _; do
  [ "$kind" = K ] && [ "${#label}" -gt "$pad" ] && pad=${#label}
done < "$CRED_FILE"

{
  echo
  rule
  title CREDENTIALS
  rule
  [ "$ready" = 1 ] || echo "# The app is not answering yet; it may still be starting."
  last=
  while IFS=$'\t' read -r kind label value; do
    case $kind in
      K) printf '# %-*s %s\n' "$((pad + 1))" "$label:" "$value" ;;
      N) [ "$last" = K ] && rule
         printf '# %s\n' "$label" ;;
    esac
    last=$kind
  done < "$CRED_FILE"
  rule
  echo
}

exit 0
