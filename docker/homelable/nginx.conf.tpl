user www-data;
worker_processes 2;
pid /run/nginx-aio.pid;
error_log /dev/stderr warn;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log off;
    sendfile on;

    map $http_x_forwarded_proto $proxy_x_forwarded_proto {
        default $http_x_forwarded_proto;
        ''      $scheme;
    }

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        # Floor plan images are uploaded through the API.
        client_max_body_size 50m;

        root /srv/homelable-web;
        index index.html;

        # From upstream's docker/nginx.conf, with the backend on 127.0.0.1:8000.
        # Live status updates (websocket), before /api/ so it wins.
        location /api/v1/status/ws/ {
            proxy_pass http://127.0.0.1:8000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 3600s;
        }

        # The API. Network scans can take a while.
        location /api/ {
            proxy_pass http://127.0.0.1:8000;
            proxy_http_version 1.1;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 600s;
        }

        # API docs (Swagger UI, ReDoc, OpenAPI schema).
        location /docs {
            proxy_pass http://127.0.0.1:8000;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /redoc {
            proxy_pass http://127.0.0.1:8000;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location = /openapi.json {
            proxy_pass http://127.0.0.1:8000;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # Legacy websocket path.
        location /ws/ {
            proxy_pass http://127.0.0.1:8000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_read_timeout 3600s;
        }

        # The web app (single-page app: unknown paths get index.html).
        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
