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

    map $http_x_forwarded_host $proxy_x_forwarded_host {
        default $http_x_forwarded_host;
        ''      $http_host;
    }

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    # From Odoo's own reverse-proxy docs (deployment/install "Odoo as a WSGI
    # application" / nginx example). Odoo runs with proxy_mode = True, so it
    # trusts the X-Forwarded-* headers set here.
    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        # Database restores and attachments can be large; Odoo decides.
        client_max_body_size 0;
        underscores_in_headers on;

        proxy_read_timeout 720s;
        proxy_connect_timeout 720s;
        proxy_send_timeout 720s;

        gzip on;
        gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;

        # Live chat, notifications and the discuss app. Port 8069 when Odoo
        # runs threaded (workers = 0), 8072 (the gevent server) with workers.
        location /websocket {
            proxy_pass http://127.0.0.1:@WS_PORT@;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Forwarded-Host $proxy_x_forwarded_host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location / {
            proxy_pass http://127.0.0.1:8069;
            proxy_http_version 1.1;
            proxy_set_header Host $http_host;
            proxy_set_header X-Forwarded-Host $proxy_x_forwarded_host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_redirect off;
        }
    }
}
