user www-data;
worker_processes 2;
pid /run/nginx-aio.pid;
error_log /dev/stderr warn;

events {
    worker_connections 4096;
}

http {
    access_log off;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # A reverse proxy in front (Nginx Proxy Manager, Caddy, a tunnel) on a
    # private address passes the visitor's IP on; anyone else's header is ignored.
    set_real_ip_from 10.0.0.0/8;
    set_real_ip_from 172.16.0.0/12;
    set_real_ip_from 192.168.0.0/16;
    set_real_ip_from 127.0.0.1;
    set_real_ip_from fc00::/7;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    map $http_x_forwarded_proto $proxy_x_forwarded_proto {
        default $http_x_forwarded_proto;
        ''      $scheme;
    }

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    # The routes are upstream's edge Caddyfile: each service under its own
    # path, with the path taken off before it is passed on.
    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        include @GUARD_FILE@;

        # Upstream's reverse-proxy rules: 512 MB uploads, websockets, idle
        # connections kept for an hour, nothing buffered.
        client_max_body_size 512m;
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_request_buffering off;
        proxy_buffering off;

        location = /_health {
            default_type text/plain;
            return 200 "OK";
        }

        location /api/ {
            proxy_pass http://127.0.0.1:8100/;
        }

        location = /gateway {
            proxy_pass http://127.0.0.1:8101/;
        }
        location /gateway/ {
            proxy_pass http://127.0.0.1:8101/;
        }

        location /media/ {
            proxy_pass http://127.0.0.1:8102/;
        }

        location /livekit/ {
            proxy_pass http://127.0.0.1:7880/;
        }

        location = /admin {
            proxy_pass http://127.0.0.1:8104/;
        }
        location /admin/ {
            proxy_pass http://127.0.0.1:8104/;
        }

        location = /.well-known/fluxer {
            proxy_pass http://127.0.0.1:8100;
        }
        location = /.well-known/webfinger {
            proxy_pass http://127.0.0.1:8100;
        }

        # fluxer-static's files and headers (its own Caddyfile).
        location ~ ^/(web|emoji|libs|avatars|badges|desktop)/ {
            root @STATIC_ROOT@;
            add_header X-Content-Type-Options nosniff always;
            add_header Referrer-Policy strict-origin-when-cross-origin always;
            add_header X-Frame-Options DENY always;
            add_header Access-Control-Allow-Origin * always;
            add_header Cache-Control "public, max-age=3600, must-revalidate" always;
            gzip on;
            gzip_types text/css application/javascript application/json image/svg+xml;
        }

        location / {
            proxy_pass http://127.0.0.1:8103;
        }
    }
}
