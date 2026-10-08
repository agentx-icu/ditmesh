[English](./README.md)

# DitMesh 公开站点

<https://agentx-icu.github.io/ditmesh/> 的源文件：App（我的 → 关于）链接、App Store
Connect 必填的隐私政策、使用条款和技术支持页。Jekyll 构建本目录；
`.github/workflows/pages.yml` 在 `master` 上每次改动 `site/` 时部署。

| 页面 | English | 简体中文 |
|---|---|---|
| 首页 | `/`（`index.md`） | `/zh-CN/` |
| 隐私政策 | `/privacy/` | `/zh-CN/privacy/` |
| 使用条款 | `/terms/` | `/zh-CN/terms/` |
| 技术支持 | `/support/` | `/zh-CN/support/` |

规则：

- 这些 URL 被 `apps/ditmesh/lib/ui/account/account_routes.dart` 和
  `doc/release/APP_STORE.zh-CN.md` 引用，三处一起改。
- 中英文页面一起改，并更新 `last_updated`。
- 条款有实质变化时同时递增 App 里的 `kTermsVersion`，让所有人在继续聊天前同意新版本。
- 支持渠道是 GitHub issues（`_config.yml` 的 `support_url`）；站点和 App 都不公布邮箱。
