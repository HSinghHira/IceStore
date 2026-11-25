---
site: https://nginx.org
source: https://github.com/nginx/nginx
services:
  - { name: Web App, path: /, icon: globe }
---

# Nginx

Nginx serves the website files you put in a folder: a homepage, a portfolio, documentation built with a static site generator, or files to share. Add your own server blocks for redirects, caching or a simple reverse proxy.

## Features

- Serves HTML, CSS, JavaScript, images and downloads fast
- Your own server blocks in conf.d
- Templates filled in from environment variables
- Gzip, caching headers and directory listings

## How to use

1. Put your website files in /DATA/AppData/nginx/html with the Files app (index.html first).
2. Open Nginx to see your site.

## Before you install

Put your website in /DATA/AppData/nginx/html; index.html is the first page. On first start, if conf.d is empty, the app creates conf.d/default.conf (a site that serves that folder) and a welcome index.html if html is empty. Add your own *.conf files to conf.d (or *.conf.template files to templates, filled in from environment variables) and restart the app to change it. Nginx has no login, so everything in html is public on your network. For HTTPS with your own domain, put a reverse proxy in front.
