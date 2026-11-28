---
source: https://github.com/gollum/gollum
screenshots: [Wiki page, Editor, Overview]
services:
  - { name: Web App, path: /, icon: globe }
---

# Gollum

Gollum is a wiki where every page is a plain file in a Git repository. Write in Markdown, AsciiDoc, Org and more, see the full history of every page, and edit the same pages in the browser or with your own editor and git.

## Features

- Markdown, AsciiDoc, Org, RDoc, Textile, MediaWiki and more
- Full page history, diffs and reverts through Git
- Search, a page tree, uploads and math with MathJax
- Diagrams with PlantUML and Mermaid
- Edit in the browser or clone the wiki and push changes

## How to use

1. Open Gollum and create the Home page.
2. Link pages with [[Page Name]] and save.

## Before you install

Gollum has no login: anyone on your network can read and edit the wiki, and every edit is saved as a Git commit by GOLLUM_AUTHOR_USERNAME. The wiki is a Git repository in /DATA/AppData/gollum/wiki, made on first start; you can clone it, edit files and commit, and the pages change in the browser.
