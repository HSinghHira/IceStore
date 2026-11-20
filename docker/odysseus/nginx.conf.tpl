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
        client_max_body_size 300m;

        # Odysseus serves the web UI, the API and its streaming chat (server-sent
        # events, websockets) on 7000. It follows the browser's address, so no
        # public URL is needed. Long answers and research runs stream for a
        # while, so no buffering and long timeouts.
        location / {
            proxy_pass http://127.0.0.1:7000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
            proxy_buffering off;
            proxy_buffer_size 32k;
            proxy_buffers 16 64k;
            proxy_max_temp_file_size 0;
        }
    }
}
