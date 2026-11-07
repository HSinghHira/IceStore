alias d := deploy

# check changed apps, then commit everything and push: `just deploy "Add Immich"`
deploy msg="Building": check platforms
    git add -A && git commit -m "{{msg}}" && git push

# run the IceStore checker on new or changed apps only; stops on the first app with an ERROR
check:
    python .github/scripts/check_changed.py

# run the IceStore checker on every app
check-all:
    python .github/scripts/check_changed.py --all

# trial run of an all-in-one app's start-up, no Docker needed: `just test k7`
test app:
    bash .github/scripts/dry_run.sh {{app}}

dev:
    python site/serve.py

# make the MOS Hub templates from Apps/ and update them in the repo root (deploy runs this)
platforms:
    python platforms/generate.py --check --write-repo

# try the generator without touching the repo: `just platforms-preview --app ntfy` -> _platforms/
platforms-preview *args:
    python platforms/generate.py --check {{args}}
