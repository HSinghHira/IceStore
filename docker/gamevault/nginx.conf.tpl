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
        # Game uploads can be huge; GameVault's own GAMES_MAX_UPLOAD_SIZE
        # (100 gb) and MEDIA_MAX_SIZE decide, not nginx.
        client_max_body_size 0;
        underscores_in_headers on;

        # GameVault serves the API, the web UI and game downloads on 8081.
        # Downloads and uploads stream straight through (no buffering, no temp
        # files) and may take hours.
        location / {
            proxy_pass http://127.0.0.1:8081;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_max_temp_file_size 0;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
            send_timeout 86400s;
        }
    }
}
