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
        # PDFs are stored in the database; uploads above this are refused.
        client_max_body_size 100m;
        underscores_in_headers on;

        # Mail viewer (mailpit, MP_WEBROOT=/mail/): the emails Documenso sends
        # while no real SMTP server is set.
        location /mail/ {
            proxy_pass http://127.0.0.1:8025;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 3600s;
        }

        # Documenso serves the web app, the API and the signing pages on 3000.
        location / {
            proxy_pass http://127.0.0.1:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 300s;
            proxy_send_timeout 300s;
            # Fonts and images are bigger than the default buffers; keep them
            # in memory and stream the rest instead of writing temp files.
            proxy_buffer_size 32k;
            proxy_buffers 16 64k;
            proxy_max_temp_file_size 0;
        }
    }
}
