alias d := deploy

# check every app, then commit everything and push: `just deploy "Add Immich"`
deploy msg="Building": check
    git add -A && git commit -m "{{msg}}" && git push

# run the IceStore checker on every app; stops on the first app with an ERROR
check:
    for a in Apps/*/; do python .claude/skills/icestore/scripts/check_app.py . "$(basename "$a")" || exit 1; done

dev:
    python site/serve.py
