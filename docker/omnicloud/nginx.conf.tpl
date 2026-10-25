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
        # Uploads of any size (upstream sets no limit either).
        client_max_body_size 0;

        root /srv/omnicloud-web;
        index index.html;

        # From upstream's frontend/docker/nginx.conf, with the API on
        # 127.0.0.1:8787. Uploads stream through to the cloud providers, so
        # no size limit and no buffering.
        location /api/ {
            proxy_pass http://127.0.0.1:8787/api/;
            proxy_http_version 1.1;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
            proxy_request_buffering off;
            proxy_buffering off;
        }

        # Live upload progress (websocket).
        location /ws/uploads {
            proxy_pass http://127.0.0.1:8787/ws/uploads;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 3600s;
        }

        # The web app (single-page app: unknown paths get index.html).
        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
