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

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    map $proxy_x_forwarded_proto $ws_scheme {
        https   wss;
        default ws;
    }

    # The routes are upstream's Caddyfile: each service under its own path,
    # with the path taken off before it is passed on.
    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        # Stoat's own upload limits decide (attachments 20 MB by default).
        client_max_body_size 100m;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
        # Plain responses from the services, so the API's addresses can be
        # rewritten below.
        proxy_set_header Accept-Encoding "";

        # Tells apps which API this server uses (upstream's stoat.json), at
        # the address the request came in on.
        location = /.well-known/stoat {
            default_type application/json;
            add_header Access-Control-Allow-Origin * always;
            return 200 '{"api":"$proxy_x_forwarded_proto://$http_host/api"}';
        }

        # The API tells the web app where the websocket, files, link
        # previews and voice are, using the addresses in Revolt.toml (made
        # from PUBLIC_URL). They are rewritten to the address the request
        # came in on, so Stoat works from the LAN IP and from a domain alike.
        location = /api {
            proxy_pass http://127.0.0.1:14702/;
            sub_filter_types application/json;
            sub_filter_once off;
            sub_filter '@PUBLIC_URL@' '$proxy_x_forwarded_proto://$http_host';
            sub_filter '@WS_URL@' '$ws_scheme://$http_host';
        }
        location /api/ {
            proxy_pass http://127.0.0.1:14702/;
            proxy_redirect / /api/;
            sub_filter_types application/json;
            sub_filter_once off;
            sub_filter '@PUBLIC_URL@' '$proxy_x_forwarded_proto://$http_host';
            sub_filter '@WS_URL@' '$ws_scheme://$http_host';
        }

        # The websocket every client keeps open.
        location = /ws {
            proxy_pass http://127.0.0.1:14703/;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
        }
        location /ws/ {
            proxy_pass http://127.0.0.1:14703/;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
        }

        location /autumn/ {
            proxy_pass http://127.0.0.1:14704/;
            proxy_redirect / /autumn/;
            proxy_request_buffering off;
            proxy_read_timeout 600s;
        }

        location /january/ {
            proxy_pass http://127.0.0.1:14705/;
            proxy_redirect / /january/;
        }

        location /gifbox/ {
            proxy_pass http://127.0.0.1:14706/;
            proxy_redirect / /gifbox/;
        }

        # LiveKit signalling (a websocket). The audio and video themselves
        # go to the LiveKit ports 6168 (TCP) and 6169 (UDP).
        location /livekit/ {
            proxy_pass http://127.0.0.1:7880/;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
        }

        location /ingress/ {
            proxy_pass http://127.0.0.1:8500/;
            proxy_redirect / /ingress/;
        }

        # The web app: static files, every other path is the app itself.
        location / {
            root @WEB_ROOT@;
            try_files $uri /index.html;
            add_header Access-Control-Allow-Origin * always;
        }
        location /assets/ {
            root @WEB_ROOT@;
            expires 30d;
            add_header Cache-Control "public, immutable";
        }
        location = /index.html {
            root @WEB_ROOT@;
            add_header Cache-Control "no-cache";
        }
    }
}
