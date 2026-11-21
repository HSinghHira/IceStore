---
site: https://semaphoreui.com/
services:
  - { name: Web UI, path: /, icon: globe }
  - { name: API, path: /api/ping, icon: code }
screenshots: [Task history]
variables:
  - name: SEMAPHORE_ADMIN_NAME
    group: First admin
    default: "Semaphore Admin"
    description: >-
      The admin's full name. Only used on the first start.
  - name: SEMAPHORE_WEB_ROOT
    group: Server
    default: ""
    description: >-
      The address you open Semaphore at, like http://192.168.1.20:6778. Used
      in links in alerts. Only read on the first start.
  - name: SEMAPHORE_ACCESS_KEY_ENCRYPTION
    group: Server
    default: ""
    description: >-
      The key saved keys and passwords are encrypted with. It is made on first
      start and kept in /data/secrets.env. Only set it to move an old install.
  - name: SEMAPHORE_MAX_PARALLEL_TASKS
    group: Server
    default: "0"
    description: >-
      How many tasks may run at once. 0 means no limit.
  - name: SEMAPHORE_EMAIL_ALERT
    group: Email alerts
    default: "false"
    description: >-
      Set to true to send alerts by email.
  - name: SEMAPHORE_EMAIL_SENDER
    group: Email alerts
    default: ""
    description: >-
      The address alerts are sent from.
  - name: SEMAPHORE_EMAIL_HOST
    group: Email alerts
    default: ""
    description: >-
      Your email server, like smtp.gmail.com.
  - name: SEMAPHORE_EMAIL_PORT
    group: Email alerts
    default: ""
    description: >-
      Your email server port, usually 587 or 465.
  - name: SEMAPHORE_EMAIL_USERNAME
    group: Email alerts
    default: ""
    description: >-
      The user name for your email server.
  - name: SEMAPHORE_EMAIL_PASSWORD
    group: Email alerts
    default: ""
    description: >-
      The password for your email server.
  - name: SEMAPHORE_EMAIL_SECURE
    group: Email alerts
    default: "false"
    description: >-
      Set to true to use TLS.
  - name: SEMAPHORE_TELEGRAM_ALERT
    group: Other alerts
    default: "false"
    description: >-
      Set to true to send alerts to Telegram.
  - name: SEMAPHORE_TELEGRAM_CHAT
    group: Other alerts
    default: ""
    description: >-
      The Telegram chat ID.
  - name: SEMAPHORE_TELEGRAM_TOKEN
    group: Other alerts
    default: ""
    description: >-
      Your Telegram bot's token.
  - name: SEMAPHORE_SLACK_ALERT
    group: Other alerts
    default: "false"
    description: >-
      Set to true to send alerts to Slack.
  - name: SEMAPHORE_SLACK_URL
    group: Other alerts
    default: ""
    description: >-
      Your Slack webhook address.
  - name: SEMAPHORE_LDAP_ACTIVATED
    group: LDAP
    default: "no"
    description: >-
      Set to yes to sign in with LDAP. Only read on the first start.
  - name: SEMAPHORE_LDAP_HOST
    group: LDAP
    default: ""
    description: >-
      Your LDAP server.
  - name: SEMAPHORE_LDAP_PORT
    group: LDAP
    default: ""
    description: >-
      Its port, usually 389 or 636.
  - name: SEMAPHORE_LDAP_DN_BIND
    group: LDAP
    default: ""
    description: >-
      The account Semaphore searches with.
  - name: SEMAPHORE_LDAP_PASSWORD
    group: LDAP
    default: ""
    description: >-
      Its password.
  - name: SEMAPHORE_LDAP_DN_SEARCH
    group: LDAP
    default: ""
    description: >-
      Where to look for users, like dc=example,dc=com.
---

# Semaphore UI

Semaphore UI runs your Ansible playbooks, Terraform and OpenTofu plans, and Bash, PowerShell and Python scripts from a web page. Keep your inventories, keys and repositories in one place, run tasks with a click or on a schedule, and see every run's log. It uses a built-in SQLite database, so it is one container with nothing else to set up.

## Features

- Ansible, Terraform, OpenTofu, Bash, PowerShell and Python tasks
- Projects with inventories, keys, repositories and variables
- Schedules, and a history with the log of every run
- Alerts by email, Telegram, Slack, Teams and more
- Teams with roles, LDAP and OIDC sign-in
- An API to start tasks from anywhere

## How to use

1. Open Semaphore UI from your dashboard.
2. Sign in with the user name and password from the app's logs (the box marked CREDENTIALS).
3. Make a project, then add a key, a repository and an inventory.
4. Add a task template for your playbook or script.
5. Click Run, and watch its log.

## Before you install

You can install it as it is and open it at `http://[ZIMAOS-IP-ADDRESS]:6778`. The admin is `SEMAPHORE_ADMIN` (`admin` unless you change it) with a password made on first start, shown in the app's logs in the box marked CREDENTIALS and saved in `/DATA/AppData/semaphore/data/.admin_password`. The key that encrypts your saved keys is made for you too. Email and chat alerts, LDAP and the other settings are in the Variables tab and are added in the app settings. It is ready in about a minute.
