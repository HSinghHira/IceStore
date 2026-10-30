alias d := deploy

# check changed apps, then commit everything and push: `just deploy "Add Immich"`
deploy msg="Building": check
    git add -A && git commit -m "{{msg}}" && git push

# run the IceStore checker on new or changed apps only; stops on the first app with an ERROR
check:
    python .github/scripts/check_changed.py

# run the IceStore checker on every app
check-all:
    python .github/scripts/check_changed.py --all

dev:
    python site/serve.py
