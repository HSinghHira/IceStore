user www-data;
worker_processes 2;
pid /run/nginx-aio.pid;
error_log /dev/stderr warn;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    # cobalt's web app loads ES modules and libav WebAssembly for on-device processing.
    types {
        text/javascript mjs;
        application/wasm wasm;
    }
    default_type application/octet-stream;
    access_log off;
    sendfile on;

    map $http_x_forwarded_proto $proxy_x_forwarded_proto {
        default $http_x_forwarded_proto;
        ''      $scheme;
    }

    # The web app and the API share "/". A browser opening the page asks for
    # text/html and gets the web app; everything else on "/" (the web app's
    # own POST requests and its server-info fetch, OPTIONS, curl, the health
    # check) goes to the API.
    map "$request_method:$http_accept" $cobalt_page {
        default                     0;
        "~^(GET|HEAD):.*text/html"  1;
    }

    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        client_max_body_size 1m;
        root /srv/cobalt-web;

        location = / {
            if ($cobalt_page) {
                rewrite ^ /index.html last;
            }
            proxy_pass http://127.0.0.1:9000;
            proxy_http_version 1.1;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
        }

        # API routes. /tunnel streams the downloaded file, so no buffering and
        # long timeouts (the API itself limits media length with DURATION_LIMIT).
        location ~ ^/(session|tunnel)$ {
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
