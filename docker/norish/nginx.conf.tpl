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

    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@

        # The "set PUBLIC_URL" note while PUBLIC_URL still says localhost
        # (written by aio-init; empty once it is set).
        include @GUARD_FILE@;

        # Recipe photos (10 MB), avatars (5 MB) and videos (100 MB) by default.
        client_max_body_size 110M;
        underscores_in_headers on;

        # Norish serves the web app, the tRPC API and its real-time websocket
        # on 3000. AI imports and video parsing can take minutes.
        location / {
            proxy_pass http://127.0.0.1:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 3600s;
            proxy_send_timeout 600s;
            proxy_buffering off;
        }
    }
}
