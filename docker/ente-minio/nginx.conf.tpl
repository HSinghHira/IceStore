user www-data;
worker_processes 2;
pid /run/nginx-aio.pid;
error_log /dev/stderr warn;

events {
    worker_connections 1024;
}

http {
    access_log off;

    map $http_x_forwarded_proto $proxy_x_forwarded_proto {
        default $http_x_forwarded_proto;
        ''      $scheme;
    }

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    # Photos web app, the mail viewer (/mail/) and the health check (/ping).
    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        client_max_body_size 64M;

        location = /ping {
            proxy_pass http://127.0.0.1:8090/ping;
        }

        location /mail/ {
            proxy_pass http://127.0.0.1:8025;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 3600s;
        }

        location / {
            proxy_pass http://127.0.0.1:3000;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
        }
    }

    # Ente API (museum). Phones and the web app talk to this port.
    server {
        listen 8081;
        client_max_body_size 0;

        location / {
            proxy_pass http://127.0.0.1:8090;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
            proxy_request_buffering off;
            proxy_buffering off;
        }
    }

    # Public albums app (the links you get when you share an album).
    server {
        listen 8082;

        location / {
            proxy_pass http://127.0.0.1:3002;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
        }
    }

    # S3 (Silo). Phones and browsers upload and download the encrypted
    # files here with pre-signed links. The Host header is passed on as-is,
    # because it is part of each link's signature. CORS is answered here, the
    # same for every store, so browsers on the photos port may use it.
    server {
        listen 8083;
        @S3_EXTRA_LISTEN@
        client_max_body_size 0;

        location / {
            proxy_hide_header Access-Control-Allow-Origin;
            proxy_hide_header Access-Control-Allow-Methods;
            proxy_hide_header Access-Control-Allow-Headers;
            proxy_hide_header Access-Control-Expose-Headers;
            proxy_hide_header Access-Control-Max-Age;
            add_header Access-Control-Allow-Origin "*" always;
            add_header Access-Control-Allow-Methods "GET, PUT, POST, DELETE, HEAD, OPTIONS" always;
            add_header Access-Control-Allow-Headers $http_access_control_request_headers always;
            add_header Access-Control-Expose-Headers "ETag, Content-Length, Content-Type" always;
            add_header Access-Control-Max-Age 3000 always;
            if ($request_method = OPTIONS) {
                return 204;
            }

            proxy_pass http://127.0.0.1:3200;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_connect_timeout 300s;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
            proxy_request_buffering off;
            proxy_buffering off;
        }
    }
}
