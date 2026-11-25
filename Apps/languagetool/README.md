---
site: https://languagetool.org
source: https://github.com/languagetool-org/languagetool
services:
  - { name: Languages, path: /v2/languages, icon: info }
variables:
  - name: Java_Xms
    group: Memory
    default: "256m"
    description: >-
      The memory LanguageTool starts with.
  - name: langtool_languageModel
    group: N-grams
    default: ""
    description: >-
      Set to /ngrams after you put n-gram data in the ngrams folder.
  - name: langtool_fasttextModel
    group: Language detection
    default: ""
    description: >-
      Path to a fastText model for better language detection.
  - name: langtool_pipelinePrewarming
    group: Server
    default: "false"
    description: >-
      Set to true to load languages at start, for faster first checks.
  - name: DISABLE_FASTTEXT
    group: Language detection
    default: "false"
    description: >-
      Set to true to skip fastText.
---

# LanguageTool

LanguageTool checks grammar, style and spelling in over 30 languages. Run your own server and point the LanguageTool browser extension, LibreOffice or Obsidian at it, so your writing never leaves your home.

## Features

- Grammar, style and spelling checks for English, German, French, Spanish, Dutch and many more
- Works with the browser extensions, LibreOffice, Thunderbird, Obsidian and editors
- Optional n-gram data for catching commonly confused words
- Simple HTTP API

## How to use

1. In the LanguageTool browser extension, open Settings, Advanced, and pick Local server or Other server with http://[ZIMAOS-IP-ADDRESS]:6839/v2.
2. Write anywhere; mistakes are underlined.

## Before you install

LanguageTool is a server for other apps and has no web page; open http://[ZIMAOS-IP-ADDRESS]:6839/v2/languages to see that it runs. Point the LanguageTool browser extension (Settings, Advanced), LibreOffice or other editors at http://[ZIMAOS-IP-ADDRESS]:6839/v2. It has no password, so keep it on your home network. Any LanguageTool server option can be added as langtool_<option>. This image is built by Erik van Leeuwen.
