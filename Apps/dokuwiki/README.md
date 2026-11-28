---
screenshots: [Wiki page]
site: https://www.dokuwiki.org/
services:
  - { name: Wiki, path: /, icon: globe }
  - { name: Installer, path: /install.php, icon: server }
variables:
  - name: PHP_MEMORYLIMIT
    group: Server
    default: "256M"
    description: >-
      Memory PHP may use. Raise it for big pages or many plugins.
---

# DokuWiki

DokuWiki is an easy wiki for notes, manuals and team knowledge. Pages are plain text files, so there is no database to look after, and backups are just a folder copy. Hundreds of plugins and templates add what you need.

## Features

- Simple wiki markup, with a toolbar and page preview
- Full history of every page, with diffs and undo
- Users, groups and page permissions (ACL)
- Full-text search and namespaces for structure
- Media manager for images and files
- Hundreds of plugins and templates from the admin panel

## How to use

1. Open DokuWiki from your dashboard. You see the installer first.
2. Name your wiki, make the admin account and pick who may read and edit.
3. Click Save, then open your wiki.
4. Search for a page that does not exist yet and click Create.

## Before you install

Right after installing, open `http://[ZIMAOS-IP-ADDRESS]:6783` and fill in the installer: it makes the admin account, and until you do, anyone on your network who opens the wiki can. Everything (pages, uploads, users, plugins) is kept as plain files in `/DATA/AppData/dokuwiki/storage`. PHP's memory limit is in the Variables tab and is added in the app settings; everything else is in DokuWiki's own Configuration Settings. It is ready in under a minute.
