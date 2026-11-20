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
        # While PUBLIC_URL still says localhost: a note for other addresses.
        include @GUARD_FILE@;
        # Same as upstream's PENPOT_HTTP_SERVER_MAX_BODY_SIZE (350 MiB).
        client_max_body_size 367001600;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;

        # Mail viewer (mailpit, MP_WEBROOT=/mail/): the emails Penpot sends
        # while no real SMTP server is set.
        location /mail/ {
            proxy_pass http://127.0.0.1:8025;
            proxy_read_timeout 3600s;
        }

        # Everything else goes to Penpot's own nginx, which routes /api,
        # /assets and /ws/notifications to the backend and /api/export to
        # the exporter, exactly as upstream ships it.
        location / {
            proxy_pass http://127.0.0.1:9001;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
            proxy_request_buffering off;
            proxy_buffering off;
        }
    }
}
