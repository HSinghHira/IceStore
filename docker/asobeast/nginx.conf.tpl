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

    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@

        client_max_body_size 50m;

        # The web app serves the pages and proxies /api/backend/* to the api
        # (upstream's topology: only the web app is published).
        location / {
            proxy_pass http://127.0.0.1:3000;
            proxy_http_version 1.1;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_buffering off;
            proxy_read_timeout 300s;
            # Upstream's production image always marks the sign-in cookie
            # Secure, which browsers drop on a plain-http LAN address. With
            # an http PUBLIC_URL, aio-init puts "proxy_cookie_flags ~ nosecure;"
            # here; with https it stays secure.
            @COOKIE_FLAGS@
        }

        error_page 502 503 504 = @not_ready;
        location @not_ready {
            default_type text/plain;
            return 503 "AsoBeast is starting.\n\nThe first start sets up the database and takes a minute or two. Reload this page soon.\n";
        }
    }
}
