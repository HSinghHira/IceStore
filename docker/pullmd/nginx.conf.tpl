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

        # File uploads (PDF, Office, EPUB, images, audio). PullMD's own fetch
        # limit is 50 MB by default (PULLMD_MAX_FETCH_BYTES).
        client_max_body_size 100M;
        underscores_in_headers on;

        # PullMD serves the web app, the REST API, the MCP server (/mcp) and
        # its progress stream (server-sent events) on 3000. Conversions of big
        # documents and transcriptions take a while: no buffering, long timeouts.
        location / {
            proxy_pass http://127.0.0.1:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            proxy_buffering off;
            proxy_request_buffering off;
        }
    }
}
