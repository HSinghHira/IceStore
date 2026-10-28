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
        client_max_body_size 20M;
        underscores_in_headers on;

        # Invidious companion: video streams, DASH segments and captions.
        # Poke links to it as <its video address>/companion/... Streams are
        # long and use Range requests: no buffering, long timeouts.
        location /companion/ {
            proxy_pass http://127.0.0.1:8282;
            proxy_http_version 1.1;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
        }

        # Poke's watch page pings a usage counter (t_url in its config).
        # It points here, so the ping never leaves this box.
        location /aio-usage-ping/ {
            return 204;
        }

        # Poke. Its config gives http://127.0.0.1:8080 as the video address
        # (so its own server-side caption fetches reach the companion through
        # this gateway); in pages and redirects sent to the browser that is
        # swapped for the address the browser used.
        location / {
            proxy_pass http://127.0.0.1:6003;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_set_header Accept-Encoding "";
            proxy_redirect http://127.0.0.1:8080/ /;
            sub_filter_types application/json text/javascript application/javascript;
            sub_filter_once off;
            sub_filter 'http://127.0.0.1:8080' '$proxy_x_forwarded_proto://$http_host';
            proxy_read_timeout 300s;
        }
    }
}
