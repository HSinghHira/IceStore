user www-data;
worker_processes 2;
pid /run/nginx-aio.pid;
error_log /dev/stderr warn;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    # cobalt's web app loads ES modules (.mjs); Debian's mime.types already has .wasm.
    types {
        text/javascript mjs;
    }
    default_type application/octet-stream;
    access_log off;
    sendfile on;

    map $http_x_forwarded_proto $proxy_x_forwarded_proto {
        default $http_x_forwarded_proto;
        ''      $scheme;
    }

    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        client_max_body_size 1m;
        root /srv/cobalt-web;

        # The API under /api (the web app is built to call <its own address>/api).
        # The prefix is stripped: /api -> /, /api/session -> /session.
        location = /api {
            proxy_pass http://127.0.0.1:9000/;
            proxy_http_version 1.1;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
        }
        location /api/ {
            proxy_pass http://127.0.0.1:9000/;
            proxy_http_version 1.1;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
        }

        # Download links. The API builds them from API_URL (= PUBLIC_URL/) as
        # <PUBLIC_URL>/tunnel?..., always at the root. They stream the file, so no
        # buffering and long timeouts (the API limits media length with DURATION_LIMIT).
        location = /tunnel {
            proxy_pass http://127.0.0.1:9000;
            proxy_http_version 1.1;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
        }

        # Hashed build files never change.
        location /_app/immutable/ {
            add_header Cache-Control "public, max-age=31536000, immutable";
            add_header Cross-Origin-Opener-Policy "same-origin";
            add_header Cross-Origin-Embedder-Policy "require-corp";
            try_files $uri =404;
        }

        # The web app: prerendered pages are <name>.html, everything else
        # falls back to the app shell (404.html). The two Cross-Origin headers
        # are upstream's (web/src/routes/_headers); on-device processing needs them.
        location / {
            add_header Cross-Origin-Opener-Policy "same-origin";
            add_header Cross-Origin-Embedder-Policy "require-corp";
            try_files $uri $uri.html $uri/index.html /404.html;
        }
    }
}
