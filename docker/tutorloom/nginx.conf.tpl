user www-data;
worker_processes 2;
pid /run/nginx-aio.pid;
error_log /dev/stderr warn;

events {
    worker_connections 1024;
}

http {
    access_log off;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    map $http_x_forwarded_proto $proxy_x_forwarded_proto {
        default $http_x_forwarded_proto;
        ''      $scheme;
    }

    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        # Course videos, documents and bulk-upload sheets.
        client_max_body_size 1g;

        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;

        # Django: the REST API, the root change-password route and the
        # Django admin (upstream's lms_core/urls.py).
        location /api/ {
            proxy_pass http://127.0.0.1:8000;
            proxy_request_buffering off;
        }
        location /auth/ {
            proxy_pass http://127.0.0.1:8000;
        }
        location /admin/ {
            proxy_pass http://127.0.0.1:8000;
        }

        # collectstatic output (Django admin, Swagger UI), from the api filesystem.
        location /static/ {
            alias /opt/rootfs/api/app/staticfiles/;
            expires 7d;
        }

        # Uploads (course thumbnails, logos, submissions, certificates).
        location /media/ {
            alias @MEDIA_ROOT@/;
        }

        # The web app: a single-page app, every other path is index.html.
        location /assets/ {
            root /opt/tutorloom-web;
            expires 30d;
            add_header Cache-Control "public, immutable";
        }
        location / {
            root /opt/tutorloom-web;
            try_files $uri /index.html;
            add_header Cache-Control "no-cache";
        }
    }
}
