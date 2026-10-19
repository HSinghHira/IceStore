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

Every app is all-in-one: the database, API, web app and workers run in a single container with one port and one data folder. Secret keys are made on first start. Each app page on the [website](https://icestore.hsinghhira.me/) lists every setting you can add in the app settings.

| App | Thumbnail |
| :--- | :--- |
| <h2><img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/affine/icon.png" width="21" height="21" alt="AFFiNE icon"> AFFiNE</h2> [![Docker image: hsinghhira/affine (latest)](https://img.shields.io/badge/hsinghhira/affine-latest-blue?style=plastic)](https://github.com/HSinghHira/IceStore/pkgs/container/affine) [![AFFiNE project page](https://img.shields.io/badge/visit-project-green?style=plastic)](https://affine.pro/) ![Port 6102](https://img.shields.io/badge/port-6102-9cf?style=plastic) <br /> Docs, whiteboards and databases in one local-first workspace — think Notion and Miro combined. Includes the web app and the admin panel at `/admin`. [More info](Apps/affine/) | <img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/affine/screenshot-1.png" width="1200" alt="AFFiNE preview"> |
| <h2><img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/appflowy/icon.png" width="21" height="21" alt="AppFlowy icon"> AppFlowy</h2> [![Docker image: hsinghhira/appflowy (latest)](https://img.shields.io/badge/hsinghhira/appflowy-latest-blue?style=plastic)](https://github.com/HSinghHira/IceStore/pkgs/container/appflowy) [![AppFlowy project page](https://img.shields.io/badge/visit-project-green?style=plastic)](https://appflowy.com/) ![Port 6101](https://img.shields.io/badge/port-6101-9cf?style=plastic) <br /> Open-source Notion alternative for notes, docs, wikis and projects. Self-hosted AppFlowy Cloud with the admin console at `/console` and a built-in mail viewer at `/mail`. [More info](Apps/appflowy/) | <img src="https://cdn.jsdelivr.net/gh/HSinghHira/IceStore@main/Apps/appflowy/screenshot-1.png" width="1200" alt="AppFlowy preview"> |

---

## Support

Found a bug or want to request an app? Open an issue on the [IceStore GitHub repository](https://github.com/HSinghHira/IceStore/issues/new).
