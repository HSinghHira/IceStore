---
site: https://github.com/AeternaLabsHQ/pullmd
services:
  - { name: Web App, path: /, icon: globe }
  - { name: Help and API, path: /help, icon: info }
  - { name: MCP Server, path: /mcp, icon: plug }
screenshots: [Convert a page, Light and dark]
variables:
  - name: PULLMD_ALLOW_SIGNUP
    group: Sign-up and accounts
    default: "true"
    description: >-
      Only for PULLMD_AUTH_MODE=multi-user. Set to false to close the sign-up
      page, so only accounts you make can sign in.
  - name: DISABLE_PUBLIC_HISTORY
    group: Sign-up and accounts
    default: "false"
    description: >-
      Set to true to hide the list of recent conversions and the archive, so
      people can't see what others fetched. Share links keep working.
  - name: OAUTH_JWT_SECRET
    group: Sign-up and accounts
    default: ""
    description: >-
      Turns on OAuth sign-in for claude.ai and Claude Desktop. Type a random
      text of at least 32 characters. Needs sign-in on and PUBLIC_URL set to
      the address claude.ai reaches.
  - name: PULLMD_AUTH_TOKEN
    group: Sign-up and accounts
    default: ""
    description: >-
      Old (v1) bearer token for single-admin mode. Only for old setups; make
      an API key in PullMD's settings instead.
  - name: PULLMD_CACHE_RETENTION_DAYS
    group: Server
    default: "90"
    description: >-
      How many days a conversion and its share link are kept without a new
      fetch. 0 keeps everything forever.
  - name: PULLMD_ALLOWED_HOSTS
    group: Server
    default: ""
    description: >-
      PullMD won't fetch addresses on your own network. List the ones it may
      fetch, separated by commas, like 192.168.1.0/24,wiki.home.
  - name: PULLMD_TRUST_PROXY
    group: Server
    default: loopback
    description: >-
      Which proxies may pass on the visitor's address. The built-in gateway
      is covered. Behind your own reverse proxy, add its address, like
      loopback,172.17.0.0/16.
  - name: PULLMD_MAX_FETCH_BYTES
    group: Server
    default: "52428800"
    description: >-
      The biggest page or document PullMD will fetch, in bytes. The default
      is 50 MB.
  - name: PULLMD_SITE_RECIPES
    group: Server
    default: ""
    description: >-
      Your own site recipes. Put the file in the app's data/pullmd folder and
      type /data/site-recipes.json here.
  - name: PULLMD_LLM_API_KEY
    group: AI for images and audio
    default: ""
    description: >-
      One API key for both image captions and audio transcripts. The
      settings below for one kind win over it.
  - name: PULLMD_LLM_BASE_URL
    group: AI for images and audio
    default: ""
    description: >-
      The OpenAI-compatible address for that key, like
      https://api.groq.com/openai/v1. Blank means OpenAI.
  - name: PULLMD_VISION_API_KEY
    group: AI for images and audio
    default: ""
    description: >-
      API key for describing images. Image captions are off until a key is
      set here or in PULLMD_LLM_API_KEY.
  - name: PULLMD_VISION_BASE_URL
    group: AI for images and audio
    default: ""
    description: >-
      The OpenAI-compatible address for image captions, like
      https://api.anthropic.com/v1 or http://192.168.1.20:11434/v1 for
      Ollama. Blank means OpenAI.
  - name: PULLMD_VISION_MODEL
    group: AI for images and audio
    default: gpt-4o-mini
    description: >-
      The model for image captions.
  - name: PULLMD_STT_API_KEY
    group: AI for images and audio
    default: ""
    description: >-
      API key for audio transcripts. Transcripts are off until a key is set
      here or in PULLMD_LLM_API_KEY.
  - name: PULLMD_STT_BASE_URL
    group: AI for images and audio
    default: ""
    description: >-
      The OpenAI-compatible address for audio transcripts. It must offer
      /audio/transcriptions. Blank means OpenAI.
  - name: PULLMD_STT_MODEL
    group: AI for images and audio
    default: whisper-1
    description: >-
      The model for audio transcripts.
  - name: PULLMD_PDF_OCR_API_KEY
    group: AI for images and audio
    default: ""
    description: >-
      API key for the paid PDF reader that keeps tables (Mistral OCR). Used
      when a request asks for ?pdf=ocr.
  - name: PULLMD_PDF_OCR_BASE_URL
    group: AI for images and audio
    default: ""
    description: >-
      The address of the PDF reader. Blank means Mistral.
  - name: PULLMD_PDF_OCR_MODEL
    group: AI for images and audio
    default: mistral-ocr-latest
    description: >-
      The model for the PDF reader.
  - name: PULLMD_LLM_RATE_LIMIT
    group: AI for images and audio
    default: "30"
    description: >-
      How many paid AI calls each person or address may make per hour. 0
      means no limit.
  - name: PULLMD_EMBEDDED_IMAGES
    group: AI for images and audio
    default: on-request
    description: >-
      Describe the images in Reddit posts: off, on-request (when asked) or
      always. Needs an image caption key.
  - name: PULLMD_EMBEDDED_IMAGES_MAX
    group: AI for images and audio
    default: "4"
    description: >-
      The most images described per post, 1 to 20.
  - name: MARKITDOWN_YOUTUBE
    group: YouTube
    default: "true"
    description: >-
      Set to false to stop turning YouTube links into transcripts.
  - name: MARKITDOWN_YT_TIMECODES
    group: YouTube
    default: links
    description: >-
      How timecodes look in transcripts: links, plain or none.
  - name: MARKITDOWN_YT_CHUNK
    group: YouTube
    default: "30"
    description: >-
      Seconds of speech per transcript block. 0 keeps YouTube's own lines.
  - name: MARKITDOWN_YT_LANGS
    group: YouTube
    default: ""
    description: >-
      The transcript languages you prefer, separated by commas, like en,de.
      Blank takes the first one there is.
  - name: MARKITDOWN_YT_PROXY
    group: YouTube
    default: ""
    description: >-
      An http(s) proxy for YouTube, like http://user:pass@proxy:8080, if
      YouTube blocks your address.
  - name: MARKITDOWN_CONVERT_TIMEOUT
    group: Documents
    default: "60"
    description: >-
      How many seconds one document may take to convert. 0 means no limit.
  - name: MARKITDOWN_MEM_LIMIT_MB
    group: Documents
    default: "0"
    description: >-
      The most memory one document conversion may use, in MB. 0 means only
      the app's memory limit counts.
  - name: REDDIT_CLIENT_ID
    group: Reddit
    default: ""
    description: >-
      The id of a "script" app from reddit.com/prefs/apps. With it, Reddit
      allows more requests per minute.
  - name: REDDIT_CLIENT_SECRET
    group: Reddit
    default: ""
    description: >-
      The secret of that Reddit app.
  - name: REDDIT_USER_AGENT
    group: Reddit
    default: ""
    description: >-
      The name PullMD gives Reddit, like linux:pullmd:1.0 (by u/yourname).
  - name: PULLMD_USER_AGENT
    group: Fetching
    default: ""
    description: >-
      One browser name to send to every site, instead of changing it each
      time.
  - name: PULLMD_UA_FEED_URL
    group: Fetching
    default: https://raw.githubusercontent.com/WinFuture23/real-world-user-agents/refs/heads/main/user-agents.json
    description: >-
      Where PullMD gets its list of current browser names. Point it at your
      own list in the same format.
  - name: PULLMD_SOURCE_HEADER
    group: Output
    default: "false"
    description: >-
      Set to true to put the title, site and date at the top of the
      Markdown, like version 2 did.
  - name: PULLMD_FRONTMATTER_FIELDS
    group: Output
    default: ""
    description: >-
      Which front matter fields to include, separated by commas, like
      title,url,source,fetched. Blank includes all.
  - name: PULLMD_COVERAGE_GUARD
    group: Output
    default: "on"
    description: >-
      Set to off to stop PullMD from retrying pages where it only caught a
      small part of the text.
  - name: PULLMD_FILENAME_DATE_PREFIX
    group: Output
    default: ""
    description: >-
      Put the date in front of downloaded file names, like YYYY-MM-DD-.
---

# PullMD

PullMD turns web pages, documents, images, audio and YouTube videos into clean Markdown. Use it from the web app, the REST API, the MCP server or a Claude skill. This is PullMD in a single container, with one port and one data folder. The Trafilatura and MarkItDown helpers are inside. The Playwright helper (headless Chromium, about 3.7 GB) is left out, so pages that need JavaScript fall back to plain extraction.

## Features

- Web pages through Cloudflare Markdown, Readability and Trafilatura
- Reddit threads and Hacker News discussions with their comments
- PDF, Word, PowerPoint, Excel and EPUB, by link or upload
- YouTube title, description and transcript with timecodes, no API key
- Image captions and audio transcripts with any OpenAI-compatible model (optional)
- Only the parts that match a question (`?query=`), to save tokens
- Share links that keep the last good copy if the page goes away
- MCP server for AI assistants, and optional sign-in with API keys

## How to use

1. Open PullMD from your dashboard.
2. Paste a link, or drop a file, and press Convert.
3. Copy or download the Markdown, or make a share link.
4. Open `http://[ZIMAOS-IP-ADDRESS]:6132/help` for the API, the MCP address and the Claude skill.

## Before you install

PullMD has no sign-in to start with, so anyone on your network can use it. To keep it to yourself, set `PULLMD_AUTH_MODE` to `single-admin` and `PULLMD_ADMIN_EMAIL` to your own email. Leave `PULLMD_ADMIN_PASSWORD` blank to get a random one, shown in the app log as "admin password is". `PUBLIC_URL` can stay as it is: PullMD follows the address you open it at. Change `localhost` to your ZimaOS IP, like `http://192.168.1.20:6132`, to get the right address in the help page and the Claude skill. Every other setting is optional and listed in the Variables tab. To use one, add it in the app settings with your value; a setting you leave out keeps its default. The first start takes about two minutes.
