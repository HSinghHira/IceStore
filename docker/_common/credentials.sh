#!/bin/sh
# Prints the CREDENTIALS banner on every boot, once the app answers, so it is
# the last thing in the log. Reads the lines written with cred_add / cred_note
# (lib.sh). Plain sh, so it also runs in wrapper images without bash.
#   credentials.sh [URL]
# All-in-one apps: supervisord starts it last ([program:credentials]) with the
# HEALTHCHECK URL. Wrapper apps: the start script runs it in the background
# (`credentials.sh URL &`) just before it hands over to the app.
# It waits for URL with curl or wget; with neither, or no URL, it waits
# CRED_DELAY seconds (default 20) instead. CRED_WAIT_SECONDS caps the wait.
CRED_FILE=${AIO_CRED_FILE:-/run/icestore/credentials}
url=${1:-}
limit=${CRED_WAIT_SECONDS:-600}

[ -s "$CRED_FILE" ] || exit 0

answers() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsS -o /dev/null -m 5 "$url" 2>/dev/null
  else
    wget -q -O /dev/null -T 5 "$url" 2>/dev/null
  fi
}

ready=1
if [ -n "$url" ] && { command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; }; then
  waited=0
  until answers; do
    if [ "$waited" -ge "$limit" ]; then ready=0; break; fi
    sleep 3
    waited=$((waited + 3))
  done
else
  delay=${CRED_DELAY:-20}
  [ "$delay" -le "$limit" ] || delay=$limit
  sleep "$delay"
fi

awk -F '\t' -v ready="$ready" '
  function hashes(n,   s) { s = ""; while (n-- > 0) s = s "#"; return s }
  { kind[NR] = $1; label[NR] = $2; value[NR] = $3
    if ($1 == "K" && length($2) > pad) pad = length($2) }
  END {
    w = 44; t = " CREDENTIALS "; l = int((w - length(t)) / 2)
    print ""
    print hashes(w); print hashes(l) t hashes(w - length(t) - l); print hashes(w)
    if (ready != 1) print "# The app is not answering yet; it may still be starting."
    last = ""
    for (i = 1; i <= NR; i++) {
      if (kind[i] == "K") printf("# %-" (pad + 1) "s %s\n", label[i] ":", value[i])
      else if (kind[i] == "N") { if (last == "K") print hashes(w); print "# " label[i] }
      last = kind[i]
    }
    print hashes(w); print ""
  }' "$CRED_FILE"

exit 0
