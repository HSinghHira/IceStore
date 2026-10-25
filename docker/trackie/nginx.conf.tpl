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

    # Trackie (Actual Budget sync server and web app).
    server {
        listen @GATEWAY_PORT@;
        @EXTRA_LISTEN@
        # Budget files are uploaded whole; Actual's own limit decides.
        client_max_body_size 100m;

        # Container health: the sign-in server, which is up before Trackie
        # is registered in it.
        location = /icestore-health {
            proxy_pass http://127.0.0.1:3001/oidc/.well-known/openid-configuration;
        }

        location / {
            proxy_pass http://127.0.0.1:5006;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 600s;
            error_page 502 503 504 = @not_ready;
        }

        # Until Trackie is registered in Logto it does not start; say so
        # instead of showing a bare 502.
        location @not_ready {
            default_type text/plain;
            return 503 "Trackie is not running yet.\n\nIf you just installed it: register Trackie in the Logto admin console (port @ADMIN_PORT@), then put the Application ID and secret in ACTUAL_OPENID_CLIENT_ID and ACTUAL_OPENID_CLIENT_SECRET in the app settings. The install tips have the steps.\n\nOtherwise it is still starting; try again in a minute.\n";
        }
    }

    # Logto sign-in server (OIDC). Trackie and your browser both use it.
    server {
        listen 8081;
        @LOGTO_EXTRA_LISTEN@
        location / {
            proxy_pass http://127.0.0.1:3001;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 120s;
            proxy_buffer_size 32k;
            proxy_buffers 16 32k;
        }
    }

    # Logto admin console.
    server {
        listen 8082;
        @ADMIN_EXTRA_LISTEN@
        location / {
            proxy_pass http://127.0.0.1:3002;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $proxy_x_forwarded_proto;
            proxy_read_timeout 120s;
            proxy_buffer_size 32k;
            proxy_buffers 16 32k;
        }
    }
}
