<!-- README-SVGS:START -->
<p align="center"><img src="readme/hero.svg" width="100%" align="top" alt="IceStore: 3rd-Party Community AppStore for Zima OS, Casa OS and Homeio"
><img src="readme/marquee.svg" width="100%" align="top" alt="Icons of the 52 apps in IceStore"
><a href="https://icestore.hsinghhira.me/#stores"><img src="readme/stores.svg" width="100%" align="top" alt="Add IceStore to ZimaOS, CasaOS or Homeio"></a
><a href="https://icestore.hsinghhira.me/#apps"><img src="readme/apps.svg" width="100%" align="top" alt="All 52 apps: AFFiNE, AppFlowy, authentik, AutoXpose, BookOrbit, Claude Code, Cloudreve, Cloudreve Pro, cobalt, Coder, Continuwuity (Matrix), deGoog, Dispatcharr, Docmost, Documenso, DocuSeal, Doory Art, Ente - Garage S3, Ente - MinIO S3, Ente - SeaweedFS S3, FluxDown, GameVault, Helix, Homedex, Homelable, Immerle, Indelible, M3U Editor, Mailpit, n8n (OIDC), Nodecast TV, ntfy, Odoo, OmniCloud, OmniRoute, openGym, Outline, Pocket ID, portracker, SearXNG, SkySend, SpiderFoot, Stoat Chat, Tianji, Trackie (Actual Budget - NZ Fork), VERT, VS Code, VSCodium, WatchYourLAN, Web-Check, Yuvomi, ZimaBrain CE"></a
><a href="https://github.com/HSinghHira/IceStore/issues/new"><img src="readme/help.svg" width="100%" align="top" alt="Missing an app? Request it on GitHub"></a
></p>
<!-- README-SVGS:END -->

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

## Support

Found a bug or want to request an app? Open an issue on the [IceStore GitHub repository](https://github.com/HSinghHira/IceStore/issues/new).
