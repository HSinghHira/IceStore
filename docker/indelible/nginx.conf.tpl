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
        # Indelible's own limits (UPLOAD_MAX_BYTES, 50 MiB, and
        # IMPORT_UPLOAD_MAX_BYTES, 200 MiB) decide; nginx lets anything up to
        # 1g through.
        client_max_body_size 1g;

        # ind-api serves the web app, the API and archived files on 3000.
        # Imports and streamed files can be large and slow, so no buffering
        # and long timeouts.
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
            proxy_send_timeout 3600s;
            proxy_request_buffering off;
            proxy_buffering off;
        }
    }
}
