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
        # Cloudreve uploads in chunks, but WebDAV clients send whole files; 0 = no limit.
        client_max_body_size 0;
        underscores_in_headers on;

        # Cloudreve serves the web app, the API (/api/v4), WebDAV (/dav) and
        # file downloads from one listener on 5212 (upstream's reverse-proxy docs).
        location / {
            proxy_pass http://127.0.0.1:5212;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
            # Stream uploads and downloads straight through instead of buffering to disk.
            proxy_request_buffering off;
            proxy_buffering off;
        }
    }
}
