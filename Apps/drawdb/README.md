---
site: https://drawdb.app/
services:
  - { name: Editor, path: /editor, icon: table }
screenshots: [Editor, Diagram]
---

# drawDB

drawDB is a database diagram (ERD) editor that runs in your browser. Draw tables and the links between them with a few clicks, then export the SQL, or import SQL you already have and see it as a diagram. No account needed.

## Features

- Tables, fields, keys and relationships on a drag-and-drop canvas
- Export SQL for MySQL, PostgreSQL, SQLite, MariaDB, SQL Server and Oracle
- Import SQL or a DBML file and get the diagram
- Notes, areas, custom types and enums
- Export as PNG, SVG, PDF or JSON
- Templates to start from, light and dark themes

## How to use

1. Open drawDB from your dashboard and click Try it.
2. Pick your database type.
3. Add tables and drag between fields to link them.
4. Use File > Export to save the SQL or a picture.

## Before you install

There is nothing to set. Open `http://[ZIMAOS-IP-ADDRESS]:6794` and start drawing. Diagrams are saved in each web browser (its local storage), not on the server, so a diagram made on one computer is not on another; use File > Export or Save as to keep a copy. Sharing by link (GitHub gists) is not set up in this build. It is ready in a few seconds.
