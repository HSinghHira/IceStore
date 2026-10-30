---
site: https://www.tutorloom.io
services:
  - { name: Web App, path: /, icon: globe }
  - { name: API Docs, path: /api/docs/, icon: code }
  - { name: Django Admin, path: /admin/, icon: server }
screenshots: [Institute admin dashboard, Course builder, Trainer dashboard, Student dashboard, Course roadmap, Progress and certificates]
variables:
  - name: TUTORLOOM_ORG_NAME
    group: First start
    default: My Academy
    description: >-
      The name of the first organization. Only used on the very first
      start; rename it later in TutorLoom.
  - name: TUTORLOOM_BATCH_NAME
    group: First start
    default: Batch 1
    description: >-
      The name of the first batch of learners. Only used on the very first
      start.
  - name: EMAIL_HOST
    group: Email (SMTP)
    default: ""
    description: >-
      Your mail server, like smtp.gmail.com. Leave it out to only write
      emails to the app logs.
  - name: EMAIL_PORT
    group: Email (SMTP)
    default: "587"
    description: >-
      Your mail server's port.
  - name: EMAIL_USE_TLS
    group: Email (SMTP)
    default: "True"
    description: >-
      Set to False for a mail server without STARTTLS.
  - name: EMAIL_HOST_USER
    group: Email (SMTP)
    default: ""
    description: >-
      The user name for your mail server.
  - name: EMAIL_HOST_PASSWORD
    group: Email (SMTP)
    default: ""
    description: >-
      The password for your mail server.
  - name: DEFAULT_FROM_EMAIL
    group: Email (SMTP)
    default: noreply@lms.com
    description: >-
      The sender address on invite and password-reset emails.
  - name: AWS_SES_ACCESS_KEY_ID
    group: Email (Amazon SES)
    default: ""
    description: >-
      An Amazon SES access key, to send emails through SES instead of SMTP.
  - name: AWS_SES_SECRET_ACCESS_KEY
    group: Email (Amazon SES)
    default: ""
    description: >-
      The Amazon SES secret key.
  - name: AWS_SES_REGION
    group: Email (Amazon SES)
    default: ap-south-1
    description: >-
      The Amazon SES region, like us-east-1.
  - name: USE_S3
    group: File storage
    default: "False"
    description: >-
      Set to True to keep uploads in Amazon S3 instead of the data folder.
  - name: AWS_S3_ACCESS_KEY_ID
    group: File storage
    default: ""
    description: >-
      The S3 access key, when USE_S3 is True.
  - name: AWS_S3_SECRET_ACCESS_KEY
    group: File storage
    default: ""
    description: >-
      The S3 secret key.
  - name: AWS_STORAGE_BUCKET_NAME
    group: File storage
    default: ""
    description: >-
      The S3 bucket name.
  - name: AWS_S3_REGION_NAME
    group: File storage
    default: ap-south-1
    description: >-
      The S3 region, like us-east-1.
  - name: THROTTLE_RATE_LOGIN
    group: Security
    default: 5/minute
    description: >-
      How many sign-in tries one address may make, like 10/minute.
  - name: THROTTLE_RATE_PASSWORD_RESET_EMAIL
    group: Security
    default: 5/hour
    description: >-
      How many password-reset emails one address may ask for.
  - name: THROTTLE_RATE_AUTH_TOKEN
    group: Security
    default: 10/minute
    description: >-
      How often one address may renew its sign-in token.
  - name: ALLOWED_HOSTS
    group: Security
    default: "*"
    description: >-
      The addresses TutorLoom may be opened at, comma separated, like
      lms.example.com,192.168.1.20. Leave it out to allow any address.
  - name: NUM_PROXIES
    group: Security
    default: "1"
    description: >-
      How many reverse proxies are in front of TutorLoom, counting the one
      inside the container. Set to 2 behind your own proxy, so sign-in
      limits see the real visitor address.
  - name: TUTORLOOM_WEB_WORKERS
    group: Performance
    default: "3"
    description: >-
      How many web processes answer requests. Raise it for many people at
      once; each one needs about 100 MB of memory.
  - name: TUTORLOOM_WORKER_CONCURRENCY
    group: Performance
    default: "2"
    description: >-
      How many background jobs (bulk uploads, emails, certificates) run at
      once.
---

# TutorLoom

TutorLoom is a learning management system (LMS) for training institutes and teams: build courses, enrol learners in batches, grade their work and follow their progress. This is TutorLoom in a single container, with the Django API, the background worker, the web app, PostgreSQL and Redis inside, one port and one data folder. The secret key, database passwords and the first admin account are made for you on first start.

## Features

- Course builder with levels, chapters and steps: videos, documents, tasks and quizzes, with prerequisites
- Batches of learners, with invites one by one or in bulk from CSV or Excel
- Portals for institute admins, trainers and students
- Grading queue with scores and written feedback, progress export to Excel and certificates
- Many organizations in one install, each with its own people and courses
- REST API with Swagger docs at `/api/docs/`

## How to use

1. Open TutorLoom from your dashboard.
2. Sign in with `ADMIN_EMAIL` and the password from the app logs (the line "TutorLoom login is").
3. Add trainers and students, make courses in the course builder and put learners in batches.
4. Trainers grade submissions; students follow their roadmap.
5. The Django admin is at `http://[ZIMAOS-IP-ADDRESS]:6177/admin/`, with the same login.

## Before you install

Set `ADMIN_EMAIL` to your own email first: on the first start it becomes the admin of a new organization (named by `TUTORLOOM_ORG_NAME`, "My Academy" if you leave it out). Leave `ADMIN_PASSWORD` empty to get a new password; it is in the app logs on the line "TutorLoom login is" and in `admin-password.txt` in the data folder. `PUBLIC_URL` starts as `http://localhost:6177`; change `localhost` to your ZimaOS IP, like `http://192.168.1.20:6177`, so links in invite emails work on other devices. The web app itself opens from any address. Until you add email settings, invite and password-reset emails are only written to the app logs. The first start takes about three minutes. Email, S3 storage and the other settings are in the Variables tab; add them in the app settings. The image is amd64 only.
