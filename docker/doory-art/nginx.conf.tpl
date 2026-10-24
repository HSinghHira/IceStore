user www-data;
worker_processes 2;
pid /run/nginx-aio.pid;
error_log /dev/stderr warn;

events {
    worker_connections 1024;
}

# Upstream's frontend/nginx.conf (the "web" container), with the upstreams on
# 127.0.0.1 instead of Docker DNS names, the SPA files in /srv/doory-web and
# the media folder in /data/media.
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log off;
    sendfile on;
    tcp_nopush on;

    upstream doory_api {
        server 127.0.0.1:8000;
        keepalive 16;
    }

    # Real-time co-editing (WebSockets) runs in its own process.
    upstream doory_realtime {
        server 127.0.0.1:8001;
    }

    # The MCP server for AI assistants (/mcp), only running with MCP_ENABLED=true.
    upstream doory_mcp {
        server 127.0.0.1:8002;
        keepalive 8;
    }

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ""      close;
    }

    # TLS is terminated by whatever sits in front (your reverse proxy). Trust its
    # X-Forwarded-Proto so Django and the HSTS header know the original scheme.
    map $http_x_forwarded_proto $forwarded_proto {
        default $http_x_forwarded_proto;
        ""      $scheme;
    }
    map $forwarded_proto $hsts_header {
        default "";
        https   "max-age=31536000; includeSubDomains";
    }

    # Trust X-Forwarded-For only from private networks (your reverse proxy, the
    # Docker bridge), so rate limiting in the API sees the real client address.
    set_real_ip_from 10.0.0.0/8;
    set_real_ip_from 172.16.0.0/12;
    set_real_ip_from 192.168.0.0/16;
    set_real_ip_from 127.0.0.1;
    set_real_ip_from fc00::/7;
    set_real_ip_from ::1;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    # Slows down password guessing against the Django admin.
    limit_req_zone $binary_remote_addr zone=admin_login:10m rate=10r/m;

    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        server_name _;

        root /srv/doory-web;
        index index.html;
        server_tokens off;

        client_max_body_size 30m;

        gzip on;
        gzip_vary on;
        gzip_proxied any;
        gzip_comp_level 5;
        gzip_min_length 512;
        gzip_types text/plain text/css text/javascript application/javascript application/json
                   application/manifest+json application/xml application/wasm image/svg+xml font/ttf font/otf;

        # ---- reverse proxy (shared settings) ----
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $forwarded_proto;
        proxy_connect_timeout 5s;
        proxy_read_timeout 120s;   # server-side PDF export can take a while
        proxy_send_timeout 120s;

        location = /healthz {
            access_log off;
            default_type text/plain;
            return 200 "ok\n";
        }

        # The API sets its own headers (security headers, cache policy, CSRF cookie...).
        location ^~ /api/ {
            proxy_pass http://doory_api;

            # Server-side export of a saved design: a video may render for up to 300 s.
            location ~ ^/api/v1/designs/[^/]+/export/image/$ {
                proxy_pass http://doory_api;
                proxy_read_timeout 330s;
                proxy_send_timeout 330s;
            }
        }

        # Uploads: a video clip may be up to MAX_VIDEO_UPLOAD_BYTES (200 MB by default).
        location = /api/v1/assets/ {
            client_max_body_size 210m;
            proxy_pass http://doory_api;
        }

        # WebSockets for live editing: long-lived, never buffered.
        location ^~ /ws/ {
            proxy_pass http://doory_realtime;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Proto $forwarded_proto;
            proxy_buffering off;
            proxy_read_timeout 1h;
            proxy_send_timeout 1h;
        }

        # MCP (Streamable HTTP). No OAuth server, so discovery under /.well-known/
        # gets a plain 404 instead of the app's index page.
        location = /mcp {
            proxy_pass http://doory_mcp;
            proxy_buffering off;
            proxy_read_timeout 330s;
            proxy_send_timeout 330s;
            client_max_body_size 5m;
        }

        location ^~ /.well-known/oauth- {
            return 404;
        }

        location ^~ /admin/ {
            proxy_pass http://doory_api;
        }

        location = /sitemap.xml {
            proxy_pass http://doory_api;
        }

        location = /admin/login/ {
            limit_req zone=admin_login burst=10 nodelay;
            limit_req_status 429;
            proxy_pass http://doory_api;
        }

        # Django static files (admin assets), served by WhiteNoise in the API.
        location ^~ /static/ {
            proxy_pass http://doory_api;
        }

        location = /media/audio/index.json {
            alias /data/media/audio/index.json;
            default_type application/json;
            add_header Cache-Control "no-cache" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header Content-Security-Policy "default-src 'none'; sandbox" always;
        }

        # Uploaded media. Names are unguessable UUIDs and never change, so they are
        # safe to cache hard. The sandbox CSP neutralises an SVG opened directly.
        location ^~ /media/ {
            alias /data/media/;
            try_files $uri =404;
            autoindex off;
            add_header Cache-Control "public, max-age=2592000, immutable" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header Content-Security-Policy "default-src 'none'; style-src 'unsafe-inline'; sandbox" always;
        }

        # Hashed build output: cache forever. A missing hashed file is a 404.
        location ^~ /assets/ {
            try_files $uri =404;
            add_header Cache-Control "public, max-age=31536000, immutable" always;
            include /etc/nginx/snippets/doory-security-headers.conf;
        }

        # The shell must always be revalidated so a new release is picked up.
        location = /index.html {
            add_header Cache-Control "no-cache" always;
            include /etc/nginx/snippets/doory-security-headers.conf;
        }

        location ~* \.(?:svg|ico|png|jpg|jpeg|webp|woff2?|txt|webmanifest)$ {
            try_files $uri =404;
            add_header Cache-Control "public, max-age=86400" always;
            include /etc/nginx/snippets/doory-security-headers.conf;
        }

        # Single-page app: every other path is a client-side route.
        location / {
            try_files $uri /index.html;
            add_header Cache-Control "no-cache" always;
            include /etc/nginx/snippets/doory-security-headers.conf;
        }
    }
}
