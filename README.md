# IceStore - Zima OS / Casa OS / Homeio Third Party Community App Store

A community app store for [ZimaOS](https://www.zimaspace.com/ZimaOS), [CasaOS](https://casaos.io/) and [Homeio](https://homeio.app/), maintained by [HSinghHira](https://github.com/HSinghHira).

Browse the apps at **[icestore.hsinghhira.me](https://icestore.hsinghhira.me/)**.

---

## 🟢 ZimaOS

ZimaOS reads app stores from a `store.json` manifest.

1. Open the **ZimaOS** dashboard.
2. Go to **App Store** → click the **⚙️ Community store**.
3. Click the ➕ icon.
4. Paste the URL below:

   ```text
   https://icestore.hsinghhira.me/store.json
   ```

5. Click **Add**, then refresh the App Store page.

> 💡 If the store doesn’t show up right away, try refreshing or restarting the App Store service — ZimaOS occasionally caches store sources.

Alternatively you can use Terminal command to add Store:

```sh
curl -s -X POST \
  -H "Authorization: $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://icestore.hsinghhira.me/store.json"}' \
  "http://localhost/v3/app_store/repo"
```

---

## 🟠 CasaOS

CasaOS doesn’t read `store.json` — instead, it can install a full custom app store from a **zip archive**.

1. Open the **CasaOS** dashboard.
2. Go to **App Store**.
3. Click **+ Add Source**.
4. Paste the store archive URL:

   ```text
   https://icestore.hsinghhira.me/store.zip
   ```

5. Click **Add**.

> 💡 If CasaOS rejects the source, use `latest.zip` instead of `store.zip`.

Alternatively you can use Terminal command to add Store:

```sh
sudo casaos-cli app-management register app-store https://icestore.hsinghhira.me/store.zip

sudo casaos-cli app-management list app-stores
```

---

## 🟣 Homeio

1. Open the **Homeio** dashboard.
2. Click **App Store**.
3. Click the **+ Install** button.
4. Go to **Manage Sources**.
5. Paste the store URL below:

   ```text
   https://icestore.hsinghhira.me/store.zip
   ```

6. Enter a name of your choice, e.g. “IceStore”.
7. Click the **Add Source** button.

> 💡 If Homeio rejects the source, use `latest.zip` instead of `store.zip`.

---

## 📦 Apps

Every app runs as a single container with one port. Multi-service apps like AFFiNE and AppFlowy are rebuilt as all-in-one images: the database, API, web app and workers run together in one container with one data folder, and secret keys are made on first start. Each app page on the [website](https://icestore.hsinghhira.me/) lists every setting you can add in the app settings.

| App | Thumbnail |
| :--- | :--- |
| <h2><img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/affine/icon.png" width="21" height="21" alt="AFFiNE icon"> AFFiNE</h2> [![Docker image: hsinghhira/affine (latest)](https://img.shields.io/badge/hsinghhira/affine-latest-blue?style=plastic)](https://github.com/HSinghHira/IceStore/pkgs/container/affine) [![AFFiNE project page](https://img.shields.io/badge/visit-project-green?style=plastic)](https://affine.pro/) ![Port 6102](https://img.shields.io/badge/port-6102-9cf?style=plastic) <br /> Docs, whiteboards and databases in one local-first workspace — think Notion and Miro combined. Includes the web app and the admin panel at `/admin`. | <img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/affine/screenshot-1.png" width="1200" alt="AFFiNE preview"> |
| <h2><img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/appflowy/icon.png" width="21" height="21" alt="AppFlowy icon"> AppFlowy</h2> [![Docker image: hsinghhira/appflowy (latest)](https://img.shields.io/badge/hsinghhira/appflowy-latest-blue?style=plastic)](https://github.com/HSinghHira/IceStore/pkgs/container/appflowy) [![AppFlowy project page](https://img.shields.io/badge/visit-project-green?style=plastic)](https://appflowy.com/) ![Port 6101](https://img.shields.io/badge/port-6101-9cf?style=plastic) <br /> Open-source Notion alternative for notes, docs, wikis and projects. Self-hosted AppFlowy Cloud with the admin console at `/console` and a built-in mail viewer at `/mail`. | <img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/appflowy/screenshot-1.png" width="1200" alt="AppFlowy preview"> |
| <h2><img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/autoxpose/icon.png" width="21" height="21" alt="AutoXpose icon"> AutoXpose</h2> [![Docker image: mostafawahied/autoxpose (0.6.0)](https://img.shields.io/badge/mostafawahied/autoxpose-0.6.0-blue?style=plastic)](https://hub.docker.com/r/mostafawahied/autoxpose) [![AutoXpose project page](https://img.shields.io/badge/visit-project-green?style=plastic)](https://github.com/mostafa-wahied/autoxpose) ![Port 6103](https://img.shields.io/badge/port-6103-9cf?style=plastic) <br /> Add a label to a container, and AutoXpose creates its DNS record and sets up your reverse proxy (Nginx Proxy Manager or Caddy) with HTTPS. | <img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/autoxpose/screenshot-1.png" width="1200" alt="AutoXpose preview"> |
| <h2><img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/claudecode/icon.png" width="21" height="21" alt="Claude Code icon"> Claude Code</h2> [![Docker image: worph/claude-code-container (1.0.28)](https://img.shields.io/badge/worph/claude--code--container-1.0.28-blue?style=plastic)](https://github.com/worph/claude-code-container/pkgs/container/claude-code-container) [![Claude Code project page](https://img.shields.io/badge/visit-project-green?style=plastic)](https://github.com/worph/claude-code-container) ![Port 6104](https://img.shields.io/badge/port-6104-9cf?style=plastic) <br /> Anthropic's Claude Code CLI in a browser terminal that keeps running when you close the tab, with an optional MCP API for automation. | <img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/claudecode/screenshot-1.png" width="1200" alt="Claude Code preview"> |
| <h2><img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/helix/icon.png" width="21" height="21" alt="Helix icon"> Helix</h2> [![Docker image: unifiedkings/helix (0.3.0)](https://img.shields.io/badge/unifiedkings/helix-0.3.0-blue?style=plastic)](https://github.com/UnifiedKings/helix/pkgs/container/helix) [![Helix project page](https://img.shields.io/badge/visit-project-green?style=plastic)](https://github.com/UnifiedKings/helix) ![Port 6105](https://img.shields.io/badge/port-6105-9cf?style=plastic) <br /> A self-hosted Pandora or Spotify for your Navidrome or Subsonic library: stations, playlist imports and shared listening lobbies. | <img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/helix/screenshot-1.png" width="1200" alt="Helix preview"> |

---

## Support

Found a bug or want to request an app? Open an issue on the [IceStore GitHub repository](https://github.com/HSinghHira/IceStore/issues/new).
