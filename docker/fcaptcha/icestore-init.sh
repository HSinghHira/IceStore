#!/bin/sh
set -eu

key_dir=/fcaptcha-data/keys

# The dashboard creates a root-owned bind mount. Prepare just the private key
# directory, then run the rest of startup and the app as the upstream user.
if [ "$(id -u)" = 0 ]; then
    install -d -m 0700 -o 65532 -g 65532 "$key_dir"
    exec su-exec 65532:65532 "$0" "$@"
fi

umask 077
key_file=$key_dir/keypair
saved_signing=
saved_verification=
if [ -f "$key_file" ]; then
    { IFS= read -r saved_signing; IFS= read -r saved_verification; } < "$key_file"
fi

select_key() {
    value=$1
    if [ -z "$value" ]; then
        value=$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')
    fi
    case "$value" in
        *[!0-9a-f]*) return 1 ;;
    esac
    [ "${#value}" -eq 64 ] || return 1
    printf '%s' "$value"
}

FCAPTCHA_SECRET=$(select_key "${FCAPTCHA_SECRET:-$saved_signing}") &&
FCAPTCHA_VERIFY_SECRET=$(select_key "${FCAPTCHA_VERIFY_SECRET:-$saved_verification}") || {
    echo '[icestore] Keys must contain 64 lowercase hexadecimal characters. Generate each with openssl rand -hex 32.' >&2
    exit 1
}
if [ "$FCAPTCHA_SECRET" = "$FCAPTCHA_VERIFY_SECRET" ]; then
    echo '[icestore] Set different signing and verification keys.' >&2
    exit 1
fi

if [ "$FCAPTCHA_SECRET" != "$saved_signing" ] || [ "$FCAPTCHA_VERIFY_SECRET" != "$saved_verification" ]; then
    if [ -f "$key_file" ]; then
        cp -p "$key_file" "$key_file.previous"
    fi
    temporary=$(mktemp "$key_dir/.keypair.XXXXXX")
    printf '%s\n%s\n' "$FCAPTCHA_SECRET" "$FCAPTCHA_VERIFY_SECRET" > "$temporary"
    mv "$temporary" "$key_file"
fi
export FCAPTCHA_SECRET FCAPTCHA_VERIFY_SECRET

exec "$@"
