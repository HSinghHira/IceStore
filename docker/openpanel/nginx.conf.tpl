user www-data;
worker_processes 2;
pid /run/nginx-aio.pid;
error_log /dev/stderr warn;

events {
    worker_connections 1024;
}

http {
    access_log off;

    # Pass on X-Forwarded-Proto from a reverse proxy in front (https), else
    # the scheme of this request.
    map $http_x_forwarded_proto $proxy_x_forwarded_proto {
        default $http_x_forwarded_proto;
        ''      $scheme;
    }

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    # Shared by every location (a location that sets its own headers would
    # drop these).
    proxy_http_version 1.1;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;

    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        include @GUARD_FILE@;

        client_max_body_size 50m;
        gzip on;
        gzip_proxied any;
        gzip_types text/plain text/css application/json application/javascript text/javascript image/svg+xml;

        # Upstream's Caddyfile: "handle_path /api*" strips /api and sends the
        # rest to the API (tracking events, tRPC, sign-in, live updates).
        location = /api {
            return 301 /api/;
        }
        location /api/ {
            proxy_pass http://127.0.0.1:3001/;
            proxy_redirect / /api/;
            proxy_buffering off;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
        }

        # Everything else is the dashboard.
        location / {
            proxy_pass http://127.0.0.1:3000;
            proxy_read_timeout 300s;
        }
    }
}
