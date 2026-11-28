---
site: https://onedev.io
source: https://github.com/theonedev/onedev
screenshots: [Dashboard, Issue boards, Pull request, Wiki]
services:
  - { name: Web App, path: /, icon: globe }
---

# OneDev

OneDev is a self-hosted Git server with everything around it: code review, issues, kanban boards, CI/CD pipelines, packages and fast code search with symbol navigation. Set it up in a few clicks and keep your code at home.

## Features

- Git repositories with pull requests, reviews and branch protection
- Built-in CI/CD with a visual job editor, running on the server or on agents
- Issues, boards, milestones and time tracking
- Code search and symbol navigation across repositories
- Package registry for Docker, npm, Maven, PyPI and more

## How to use

1. Open OneDev right away and make the admin account in the setup page.
2. Set the server URL to http://[ZIMAOS-IP-ADDRESS]:6842 with your ZimaOS IP.
3. Create a project and push your code.

## Before you install

Right after installing, open http://[ZIMAOS-IP-ADDRESS]:6842 and make the admin account; until you do, anyone on your network can. In the setup page set the server URL to that address and the SSH root URL to ssh://[ZIMAOS-IP-ADDRESS]:6843. CI jobs run on the server itself in shell executors; running jobs in containers needs Docker access, which this app does not get.
