# 决策：入口页改为「tab 壳 + 按需加载」并迁到 Vercel（2026-09-27）

## 问题

- 原入口页是「侧边栏链接 + 单个 iframe 换 `src`」：首屏无条件加载最新周（5.73 MiB 原始 / 3.31 MiB brotli），点任意周都会换 `src` 重新下载——Vercel 对 HTML 返回 `max-age=0, must-revalidate`，切回看过的周必然重新校验或重下。
- 侧边栏条目原本 `target="_blank"`，点击会跳新标签打开报告，同时切换 iframe 预览；一周两处动作，交互不干净。
- `code/update_site.R` 把约 100 行 CSS 当 R 字符串字面量拼进 HTML：编辑器无法高亮/校验，改样式要改 R 代码。
- 维护者诉求：想要「全部周都在页面上」的形体，但**不要**首屏下载全部 28 MiB。

## 决策

- **方案 B：多文件 + 按需加载**。根 `index.html` 只做 tab 壳；每周一个 iframe，首次点击该周才创建并设 `src`，已创建的留在 DOM 里切显隐，切回零请求。
- 明确否决「单 iframe 换 `src`」：缓存策略不可控，切回会重复下载。
- 明确否决「全部内嵌在单页」：见下方替代方案。
- 展示逻辑抽到 `assets/site/`：`index.template.html` + `hub.css` + `hub.js`，`update_site.R` 只做占位符替换，仍是纯 base R。
- 每周条目右侧保留 GitHub 八爪鱼链接，指向该周仓库目录；tab 本身不再跳转。
- 托管由 Vercel 承担：workflow 只保留「生成 → 有变化则 commit `index.html` 回 main」，Vercel 经 Git 集成部署；GitHub Actions 不再参与部署。

## 替代方案与否决理由

- **单页全量内嵌（直接拼接 DOM）**：七份报告各自自带 Bootstrap + Quarto 样式，且跨周重复 10 个元素 id（`quarto-content`、`quarto-document-content`、`TOC`、`toc-title`、`title-block-header`、`quarto-sidebar-toc-left`、`quarto-margin-sidebar`、`quarto-html-after-body`、`quarto-bootstrap`、`quarto-text-highlighting-styles`）与 2 个 `link/style` id，加上各约 340 KB + 430 KB 的全局 `<style>`（含 `@font-face` base64 字体与 `:root` 变量），拼接必然冲突。首屏还要下载 28 MiB。- **Shadow DOM 隔离**：`innerHTML` 注入的 `<script>` 不执行，报告里的图表与 TOC 脚本全部失效。
- **`<iframe loading="lazy">`**：实测面板为一屏高时 7 个 iframe **全部立即加载**（初始 8 个 document 请求 / 28.47 MiB）；只有把面板做到 300vh 才延迟到 3/7。行为取决于浏览器视口距离阈值，不可控，故不用它决定加载时机。
- **Quarto website / listing / `{{< embed >}}` / `{{< include >}}` / book / dashboard**：都无法表达「单入口 tab 切换多份已渲染的自包含报告」——`embed`/`include` 在渲染期解析而非运行期，website/book 天然产出多页。
- **手写 `index.html` 周清单**：与既有决策「入口页由脚本生成」冲突，清单会漂。

## 实测数据（本地 Playwright，cache disabled）

| 场景 | 报告请求数 |
| --- | --- |
| 首屏加载 | 0 |
| 点第 1 周 | 1 |
| 再点第 4、第 7 周 | 2 → 3 |
| 切回第 4、第 1 周 | 3 → 3（零请求） |

传输体积：单周原始 3.38–5.73 MiB；Vercel 实测协商到 brotli（`Content-Encoding: br`，单周 3.31 MiB）与 gzip（3.34 MiB），七周合计原始 28.47 MiB / gzip 14.39 MiB。

Vercel 对 HTML 返回 `cache-control: public, max-age=0, must-revalidate`：即使命中也走条件请求。
因此「已看过的周切回零请求」不能依赖缓存，只能靠面板留在 DOM 里——这正是每周一个常驻 iframe（而不是单个 iframe 换 `src`）的理由。

## 影响

- 契约新增：入口页输入固定名 `assets/site/index.template.html` / `hub.css` / `hub.js` 与四个占位符；`code/update_site.R` 在注入前校验「模板缺占位符 / 有未知占位符」并直接报错。已同步 [../docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md)、[../../weeks/README.md](../../weeks/README.md)、[../../code/README.md](../../code/README.md)、[../../README.md](../../README.md)、[../../AGENTS.md](../../AGENTS.md)。
- 不再把「本地双击 `file://`」当硬约束（目标改为远程 Vercel）；按需加载在 `file://` 下亦实测可用。
- 已知遗留（与本次改动无关）：`weeks/2026-08-04/output/02_exploratory_visualization.html` 自带一个运行期 JS 报错（`i.map is not a function`，位于其内嵌 plotly 代码 `getScales`），单独打开该报告同样复现。
