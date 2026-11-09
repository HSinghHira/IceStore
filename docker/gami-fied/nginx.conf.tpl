user www-data;
worker_processes 2;
pid /run/nginx-aio.pid;
error_log /dev/stderr warn;

events {
    worker_connections 1024;
}

http {
    access_log off;

    # Pass on X-Forwarded-Proto from a reverse proxy in front (https), else
    # the scheme of this request.
    map $http_x_forwarded_proto $proxy_x_forwarded_proto {
        default $http_x_forwarded_proto;
        ''      $scheme;
    }

    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    # Upstream's Caddyfile.example on one address: browser API calls go
    # straight to the api, everything else to the dashboard.
    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        include @GUARD_FILE@;

        client_max_body_size 50m;

        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_read_timeout 300s;

        location /api/ {
            proxy_pass http://127.0.0.1:3001;
        }

        location /v1/ {
            proxy_pass http://127.0.0.1:3001;
        }

        location / {
            proxy_pass http://127.0.0.1:3000;
        }

        error_page 502 503 504 = @not_ready;
        location @not_ready {
            default_type text/plain;
            return 503 "Gami.Fied is starting.\n\nThe first start sets up the database and takes a minute or two. Reload this page soon.\n";
        }
    }
}
