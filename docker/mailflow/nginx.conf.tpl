user www-data;
worker_processes 2;
pid /run/nginx-aio.pid;
error_log /dev/stderr warn;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    types {
        application/manifest+json webmanifest;
    }
    default_type application/octet-stream;
    access_log off;
    sendfile on;

    map $http_x_forwarded_proto $proxy_x_forwarded_proto {
        default $http_x_forwarded_proto;
        ''      $scheme;
    }

    # Upstream's compression settings. The AI assistant's text/event-stream is
    # left out, so it keeps streaming.
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 5;
    gzip_min_length 1024;
    gzip_types application/json application/javascript text/css text/plain image/svg+xml application/manifest+json;

    # This is upstream's port 80 server (frontend/nginx.conf), with the backend
    # on 127.0.0.1:3000 instead of a separate container.
    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        server_name _;

        root /srv/mailflow-web;
        index index.html;

        client_max_body_size 50m;

        proxy_buffer_size       128k;
        proxy_buffers           4 256k;
        proxy_busy_buffers_size 256k;

        # Shared by every proxied location below that sets no headers of its own.
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;

        # Security headers. HSTS is left out: it belongs on an HTTPS proxy.
        add_header X-Content-Type-Options    "nosniff" always;
        add_header X-Frame-Options           "SAMEORIGIN" always;
        add_header Referrer-Policy           "strict-origin-when-cross-origin" always;
        add_header Permissions-Policy        "camera=(), microphone=(), geolocation=()" always;
        add_header Content-Security-Policy   "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com data: https:; img-src 'self' data: https: blob:; connect-src 'self' wss: ws:; frame-src 'self'; object-src 'none'; base-uri 'self';" always;

        # The backend only accepts a WebSocket whose Origin is exactly APP_URL
        # (= PUBLIC_URL). So that live updates also work when the app is opened
        # on another address (the ZimaOS IP while PUBLIC_URL says localhost, or a
        # domain), a same-origin request (Origin matches the address the browser
        # used) is passed on with PUBLIC_URL's origin. Any other Origin is passed
        # on unchanged, and the backend still rejects it.
        set $ws_origin $http_origin;
        if ($http_origin = "$proxy_x_forwarded_proto://$http_host") {
            set $ws_origin "@PUBLIC_ORIGIN@";
        }

        # OAuth (Google, Microsoft) and OIDC sign-in redirects
        location /oauth/ {
            proxy_pass http://127.0.0.1:3000;
            proxy_read_timeout 60s;
        }
        location /auth/oidc/ {
            proxy_pass http://127.0.0.1:3000;
            proxy_read_timeout 30s;
        }

        # Long-running: running rules goes through every inbox message over IMAP
        location = /api/rules/run {
            proxy_pass http://127.0.0.1:3000;
            proxy_read_timeout 300s;
        }

        # AI streaming (SSE): long timeout, no buffering
        location /api/ai/ {
            proxy_pass http://127.0.0.1:3000;
            proxy_read_timeout 300s;
            proxy_buffering off;
            proxy_cache off;
        }

        # Backup download and restore upload: the whole database, so no size
        # cap, no buffering and long timeouts.
        location /api/admin/backup {
            proxy_pass http://127.0.0.1:3000;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
            proxy_buffering off;
            proxy_request_buffering off;
            client_max_body_size 0;
        }

        location /api/ {
            proxy_pass http://127.0.0.1:3000;
            proxy_read_timeout 60s;
        }

        # WebSocket. Setting headers here drops the shared ones, so all are repeated.
        location /ws {
            proxy_pass http://127.0.0.1:3000;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Origin $ws_origin;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 86400s;
        }

        # CardDAV. No trailing slash on purpose: /carddav/ would make nginx
        # answer /carddav itself with a redirect.
        location /carddav {
            proxy_pass http://127.0.0.1:3000;
            proxy_read_timeout 60s;
        }
        location /.well-known/carddav {
            proxy_pass http://127.0.0.1:3000;
            proxy_read_timeout 60s;
        }

        # The web app. HTML is never cached, so browsers always get the current
        # script names. add_header here replaces the server ones, so they are repeated.
        location / {
            try_files $uri $uri/ /index.html;
            add_header Cache-Control "no-store" always;
            add_header X-Content-Type-Options    "nosniff" always;
            add_header X-Frame-Options           "SAMEORIGIN" always;
            add_header Referrer-Policy           "strict-origin-when-cross-origin" always;
            add_header Permissions-Policy        "camera=(), microphone=(), geolocation=()" always;
            add_header Content-Security-Policy   "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com data: https:; img-src 'self' data: https: blob:; connect-src 'self' wss: ws:; frame-src 'self'; object-src 'none'; base-uri 'self';" always;
        }

        # The service worker (push notifications) must update right away.
        location = /sw.js {
            add_header Cache-Control "no-store" always;
            add_header X-Content-Type-Options    "nosniff" always;
            add_header X-Frame-Options           "SAMEORIGIN" always;
            add_header Referrer-Policy           "strict-origin-when-cross-origin" always;
            add_header Permissions-Policy        "camera=(), microphone=(), geolocation=()" always;
            add_header Content-Security-Policy   "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com data: https:; img-src 'self' data: https: blob:; connect-src 'self' wss: ws:; frame-src 'self'; object-src 'none'; base-uri 'self';" always;
        }

        # Hashed build files never change.
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
