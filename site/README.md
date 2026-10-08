[简体中文](./README.zh-CN.md)

# DitMesh public site

Source of <https://agentx-icu.github.io/ditmesh/>: the privacy policy, terms of
use and support page the app links to (Me → About) and App Store Connect
requires. Jekyll builds this directory; `.github/workflows/pages.yml` deploys
it on every push to `master` that touches `site/`.

| Page | English | 简体中文 |
|---|---|---|
| Home | `/` (`index.md`) | `/zh-CN/` |
| Privacy policy | `/privacy/` | `/zh-CN/privacy/` |
| Terms of use | `/terms/` | `/zh-CN/terms/` |
| Support | `/support/` | `/zh-CN/support/` |

Rules:

- The URLs are referenced from `apps/ditmesh/lib/ui/account/account_routes.dart`
  and `doc/release/APP_STORE.md`; change all three together.
- Edit the English and the Chinese page together and bump `last_updated`.
- A material change to the terms also bumps `kTermsVersion` in the app, so
  everyone agrees to the new version before chatting again.
- The support contact is GitHub issues (`support_url` in `_config.yml`); the
  site and the app publish no e-mail address.
