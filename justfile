deploy:
    git add -A && git commit -m "Building" && git push
d:
    git add -A && git commit -m "Building" && git push
dev:
    python site/serve.py 