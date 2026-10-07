# Digital IC Classroom 学习网站

独立 Astro 静态网站，正式地址：[Digital IC Classroom](https://why250-digital-ic-classroom.pages.dev/)。
模拟课堂的首页和共享导航设有“数字 IC 课堂”入口；本站导航与页脚可返回 [Circuits & Systems Classroom](https://why250-circuits-classroom.pages.dev/)。

## 内容与记录

- 直接读取 [原有课程](../docs/roadmap.md)，生成六个方向、94 课的目录、讲义、参考答案与项目页面，不复制维护讲义正文。
- 课程目录支持标题与正文搜索；阅读页有课程导航、本页目录、源码阅读和个人记录。
- 学习状态与笔记使用当前浏览器 localStorage。可导出 JSON 备份、导入合并；同一课以导入记录为准。没有账号或云端同步。
- SPI 交互演示使用 50 MHz clk，展示 Mode 0、MSB first、独立 TX/RX、分频 1/3/25 和八次采样；属于契约生成的理想教学模型，不替代真实 RTL 回归。
- Git 忽略的 VCD/SVG/报告链接转到本地产物说明页，不将生成产物、安装工具、官方教程库、许可或 PDK 上传网站。

## 本地开发

Node ≥22.12、pnpm 11，在 `web/` 运行：

```powershell
pnpm install --frozen-lockfile
pnpm dev
pnpm check
pnpm test
pnpm build
pnpm test:browser
```

开发与预览地址为 `http://127.0.0.1:4322`，浏览器测试用独立前台进程和端口 4323。首次浏览器测试可运行 `pnpm exec playwright install chromium`；已有 Chromium 可通过当前命令环境的 `PLAYWRIGHT_EXECUTABLE_PATH` 复用，配置不写入机器专属路径。

模型/数据测试覆盖课程编号和锚点、Markdown 链接、SPI 全部 256 码与三组分频、学习备份校验与合并；浏览器测试覆盖搜索、阅读导航、笔记持久化、备份、SPI 控件及手机布局。

## Cloudflare Pages 发布

```powershell
node scripts/deploy-pages.mjs --prepare-only
node scripts/deploy-pages.mjs
```

先构建并在 `.wrangler/static-pages-*` 中准备隔离静态产物，再使用已有 Pages 登录创建或复用 `why250-digital-ic-classroom`。需要登录时使用 `node node_modules/wrangler/bin/wrangler.js login --device --browser=false --scopes account:read user:read pages:write`；凭据始终由 Wrangler 保存在源码之外。

项目名可用 `--project <name>` 修改；构建时 `SITE_URL` 随之更新 canonical / sitemap。Cloudflare 部署成功后仍需检查正式网址与模拟课堂跳转。发布不自动提交或推送 Git。

根目录的 EDA 部署工具 `tools/deploy.ps1` 排除 `web/`，保留原有普通 scp 与逐文件 SHA-256 核验。网页使用上述独立 Pages 流程发布，不上传到 IC_Server。

兄弟网站的目标地址集中在其 `web/src/data/learning-sites.ts`，可用 `DIGITAL_IC_SITE_URL` 环境变量覆盖。本站正文、路线与证据继续分别维护在 docs 下的原文件。
