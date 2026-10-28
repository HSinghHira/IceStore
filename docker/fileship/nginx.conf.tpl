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

        # Uploads come in chunks (25 MB by default, set in the dashboard).
        # Upstream's Caddy proxy has no size limit, so neither does this.
        client_max_body_size 0;

        # Same as upstream's Caddy: trust X-Forwarded-For only from private
        # addresses (a reverse proxy on your network), then hand Fileship the
        # real client address in X-Fileship-Client-IP.
        set_real_ip_from 10.0.0.0/8;
        set_real_ip_from 172.16.0.0/12;
        set_real_ip_from 192.168.0.0/16;
        set_real_ip_from 127.0.0.0/8;
        set_real_ip_from fd00::/8;
        set_real_ip_from ::1;
        real_ip_header X-Forwarded-For;
        real_ip_recursive on;

        # Fileship serves the dashboard, the API, uploaded files and its
        # websockets (/socket.io/ and others) on 3000. Streaming and long
        # downloads, so no buffering and long timeouts.
        location / {
            proxy_pass http://127.0.0.1:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_set_header X-Fileship-Client-IP $remote_addr;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
            proxy_buffering off;
            proxy_request_buffering off;
        }
    }
}
