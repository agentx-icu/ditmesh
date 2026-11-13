[English](./README.md)

# DitMesh 公开站点

<https://agentx-icu.github.io/ditmesh/> 的源文件，提供商店资料使用的公开隐私政策、
使用条款和技术支持页面。Jekyll 构建本目录。
`.github/workflows/pages.yml` 在 `master` 上每次改动 `site/` 时部署。

| 页面 | English | 简体中文 |
|---|---|---|
| 首页 | `/`（`index.md`） | `/zh-CN/` |
| 隐私政策 | `/privacy/` | `/zh-CN/privacy/` |
| 使用条款 | `/terms/` | `/zh-CN/terms/` |
| 技术支持 | `/support/` | `/zh-CN/support/` |

规则：

- 公开网址与 `doc/release/APP_STORE.zh-CN.md` 保持一致。
- 同时修改中英文页面并更新 `last_updated`。同步更新 `apps/ditmesh/assets/legal/`
  中全部十种语言的应用内正文。每种语言各有 `privacy_<locale>.txt` 和
  `terms_<locale>.txt` 两份文件。
- 条款有实质变化时同时递增 App 里的 `kTermsVersion`，让所有人在继续聊天前同意新版本。
- 公开支持页指向 GitHub issues（`_config.yml` 的 `support_url`）。应用的
  「我 → 隐私与权限 → 技术支持」提供故障排查和问题报告指引。
