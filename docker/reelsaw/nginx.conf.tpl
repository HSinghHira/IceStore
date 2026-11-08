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
        include @GUARD_FILE@;

        # Video uploads (upstream's MAX_UPLOAD_MB default is 4096).
        client_max_body_size 0;

        # Reelsaw serves the web app, the API, live updates (SSE) and MCP on
        # one port. No buffering, so uploads stream and live updates arrive
        # at once.
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
            proxy_request_buffering off;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
        }

        # Reelsaw not running yet, or stopped at start (most often no AI
        # key): say so instead of a bare 502.
        error_page 502 503 504 = @not_ready;
        location @not_ready {
            default_type text/plain;
            return 503 "Reelsaw is not running yet.\n\nThe first start takes a minute or two. If this stays, open the app log in ZimaOS: Reelsaw stops at start when it can't use an AI provider. Set OPENAI_API_KEY (or another provider from the Variables tab on https://icestore.hsinghhira.me/app/reelsaw/) in the app settings and save.\n";
        }
    }
}
