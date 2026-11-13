[简体中文](./README.zh-CN.md)

# DitMesh public site

Source of <https://agentx-icu.github.io/ditmesh/> and the public privacy, terms
and support URLs used in store listings. Jekyll builds this directory.
`.github/workflows/pages.yml` deploys it on every push to `master` that
touches `site/`.

| Page | English | 简体中文 |
|---|---|---|
| Home | `/` (`index.md`) | `/zh-CN/` |
| Privacy policy | `/privacy/` | `/zh-CN/privacy/` |
| Terms of use | `/terms/` | `/zh-CN/terms/` |
| Support | `/support/` | `/zh-CN/support/` |

Rules:

- Keep the public URLs in sync with `doc/release/APP_STORE.md`.
- Edit the English and Chinese pages together and update `last_updated`.
  Sync the in-app copies in `apps/ditmesh/assets/legal/` for all ten supported
  locales. Each locale has a `privacy_<locale>.txt` and a `terms_<locale>.txt`.
- A material change to the terms also bumps `kTermsVersion` in the app, so
  everyone agrees to the new version before chatting again.
- The public support page points to GitHub issues (`support_url` in
  `_config.yml`). Me → Privacy and permissions → Technical support provides
  troubleshooting and reporting guidance inside the app.
