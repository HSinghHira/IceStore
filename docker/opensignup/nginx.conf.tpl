user nginx;
worker_processes 2;
pid /run/nginx-icestore.pid;
error_log /dev/stderr warn;

events {
    worker_connections 1024;
}

http {
    access_log off;
    default_type text/plain;

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
        client_max_body_size 10m;

        # While PUBLIC_URL is on localhost, other addresses get a note
        # saying what to set instead of links that lead to localhost.
        include @GUARD_FILE@;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;

        # Mail viewer (mailpit, MP_WEBROOT=/mail/): the sign-in and reminder
        # emails while no SMTP server is set.
        location = /mail {
            return 301 /mail/;
        }
        location /mail/ {
            proxy_pass http://127.0.0.1:8025;
            proxy_read_timeout 3600s;
        }

        # OpenSignup: pages, the API, the MCP server and sign-in.
        location / {
            proxy_pass http://127.0.0.1:3000;
            # Magic Compose (AI drafts) can take minutes (LLM_TIMEOUT_MS).
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
            proxy_buffer_size 32k;
            proxy_buffers 16 64k;
            proxy_max_temp_file_size 0;
        }
    }
}
