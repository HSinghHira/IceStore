---
site: https://www.bytebase.com
source: https://github.com/bytebase/bytebase
screenshots: [SQL editor, Change review]
services:
  - { name: Web App, path: /, icon: globe }
variables:
  - name: PG_URL
    group: Database
    default: ""
    description: >-
      Your own PostgreSQL for Bytebase's data instead of the built-in
      one, like postgresql://user:pass@192.168.1.20:5432/bytebase.
---

# Bytebase

Bytebase is a web workspace for your databases. Review and roll out schema changes, query data in a shared SQL editor, and control who may see or change what, for PostgreSQL, MySQL, SQL Server, Oracle, MongoDB and more.

## Features

- SQL review with over 200 lint rules before changes run
- Change history, drift detection and rollback plans
- Web SQL editor with data masking and access requests
- Projects, roles and approval flows for teams
- GitOps with GitHub, GitLab, Bitbucket and Azure DevOps
- Over 20 database engines

## How to use

1. Open Bytebase right away and make the admin account.
2. Add a database instance with its host, port and login.
3. Open the SQL editor, or start a change in a project.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6823 and make the admin account; until you do, anyone on your network can. Bytebase keeps its own data in a built-in PostgreSQL in /DATA/AppData/bytebase/data. Some features (SSO, data masking, more users) need a paid plan; the free plan covers one workspace.
