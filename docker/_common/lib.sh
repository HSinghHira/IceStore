# shellcheck shell=bash
# Shared helpers for IceStore all-in-one images. The build copies this file to
# /usr/local/lib/icestore/lib.sh; aio-init.sh sources it after setting SECRETS.
#
#   log TEXT...                     print "[init] TEXT"
#   ensure_secret NAME BYTES [PRE]  add NAME=<PRE><random hex> to $SECRETS once;
#                                   sets NEW_<NAME>=1 when it was just made
#   secret NAME                     print a saved secret
#   cred_reset                      start an empty credentials list (every boot)
#   cred_add LABEL VALUE            add a line to the CREDENTIALS banner
#   cred_note TEXT                  add a free-text line under the banner lines

log() { echo "[init] $*"; }

ensure_secret() {
  local name=$1 bytes=$2 prefix=${3:-}
  if ! grep -q "^$name=" "$SECRETS"; then
    echo "$name=$prefix$(openssl rand -hex "$bytes")" >> "$SECRETS"
    printf -v "NEW_$name" 1
  fi
  return 0
}

secret() { sed -n "s/^$1=//p" "$SECRETS"; }

# The banner is read by credentials.sh, which supervisord starts last.
CRED_FILE=${AIO_CRED_FILE:-/run/icestore/credentials}

cred_reset() {
  mkdir -p "$(dirname "$CRED_FILE")"
  (umask 077; : > "$CRED_FILE")
}

cred_add() { printf 'K\t%s\t%s\n' "$1" "$2" >> "$CRED_FILE"; }

cred_note() { printf 'N\t%s\n' "$1" >> "$CRED_FILE"; }
