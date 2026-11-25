---
site: https://ollama.com
source: https://github.com/ollama/ollama
services:
  - { name: Version, path: /api/version, icon: info }
variables:
  - name: OLLAMA_NUM_PARALLEL
    group: Performance
    default: "1"
    description: >-
      How many requests one model answers at the same time.
  - name: OLLAMA_MAX_LOADED_MODELS
    group: Performance
    default: ""
    description: >-
      How many models may be in memory at once.
  - name: OLLAMA_CONTEXT_LENGTH
    group: Performance
    default: "4096"
    description: >-
      The default context size in tokens.
  - name: OLLAMA_ORIGINS
    group: Network
    default: ""
    description: >-
      Web addresses allowed to call Ollama from a browser, comma
      separated, like http://192.168.1.20:6845.
  - name: OLLAMA_DEBUG
    group: Logging
    default: ""
    description: >-
      Set to 1 for detailed logs.
---

# Ollama

Ollama downloads and runs open language models like Llama, Gemma, Qwen, Mistral and DeepSeek on your ZimaOS, and serves them through an API that chat apps such as Open WebUI, big-AGI and NextChat can use. It runs on the CPU here; small models work best.

## Features

- Hundreds of models from the Ollama library, pulled with one command
- OpenAI-compatible API at /v1, plus Ollama's own API
- Embeddings, vision and tool calling with supporting models
- Models load on demand and unload when idle

## How to use

1. Pull a model: docker exec ollama ollama pull llama3.2 (or from a chat app that can pull models).
2. Point your chat app at http://[ZIMAOS-IP-ADDRESS]:6844 with your ZimaOS IP.

## Before you install

Ollama is a server for chat apps and has no web page; open http://[ZIMAOS-IP-ADDRESS]:6844/api/version to see that it runs. Pull models with docker exec ollama ollama pull <model> or from a chat app such as Open WebUI. This app runs models on the CPU; it does not set up a GPU, so pick small models and expect slower answers. Ollama has no password, so keep it on your home network. A browser app on another address needs that address in OLLAMA_ORIGINS.
