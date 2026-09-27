# 决策：入口页改为「薄外壳 + 按需加载」并迁到 Vercel（2026-09-27）

## 问题

- 原入口页是「侧边栏链接 + 单个 iframe 换 `src`」：首屏无条件加载最新周（5.73 MiB 原始 / 3.31 MiB brotli），点任意周都会换 `src` 重新下载——Vercel 对 HTML 返回 `max-age=0, must-revalidate`，切回看过的周必然重新校验或重下。
- 侧边栏条目原本 `target="_blank"`，点击会跳新标签打开报告，同时切换 iframe 预览；一周两处动作，交互不干净。
- `code/update_site.R` 把约 100 行 CSS 当 R 字符串字面量拼进 HTML：编辑器无法高亮/校验，改样式要改 R 代码。
- 维护者诉求：想要「全部周都在页面上」的形体，但**不要**首屏下载全部 28 MiB。

## 决策

- **方案 B：多文件 + 按需加载**。根 `index.html` 只做外壳（薄顶栏 + 默认收起的抽屉列周）；每周一个 iframe，进页面先建最新一周、其余周首次选中才创建并设 `src`，已创建的留在 DOM 里切显隐，切回零请求。
- 明确否决「单 iframe 换 `src`」：缓存策略不可控，切回会重复下载。
- 明确否决「全部内嵌在单页」：见下方替代方案。
- 展示逻辑抽到 `assets/site/`：`index.template.html` + `hub.css` + `hub.js`，`update_site.R` 只做占位符替换，仍是纯 base R。
- 每周条目右侧保留 GitHub 八爪鱼链接，指向该周仓库目录；周次按钮本身不再跳转。
- 托管由 Vercel 承担：workflow 只保留「生成 → 有变化则 commit `index.html` 回 main」，Vercel 经 Git 集成部署；GitHub Actions 不再参与部署。

## 替代方案与否决理由

- **单页全量内嵌（直接拼接 DOM）**：七份报告各自自带 Bootstrap + Quarto 样式，且跨周重复 10 个元素 id（`quarto-content`、`quarto-document-content`、`TOC`、`toc-title`、`title-block-header`、`quarto-sidebar-toc-left`、`quarto-margin-sidebar`、`quarto-html-after-body`、`quarto-bootstrap`、`quarto-text-highlighting-styles`）与 2 个 `link/style` id，加上各约 340 KB + 430 KB 的全局 `<style>`（含 `@font-face` base64 字体与 `:root` 变量），拼接必然冲突。首屏还要下载 28 MiB。
- **Shadow DOM 隔离**：`innerHTML` 注入的 `<script>` 不执行，报告里的图表与 TOC 脚本全部失效。
- **`<iframe loading="lazy">`**：实测面板为一屏高时 7 个 iframe **全部立即加载**（初始 8 个 document 请求 / 28.47 MiB）；只有把面板做到 300vh 才延迟到 3/7。行为取决于浏览器视口距离阈值，不可控，故不用它决定加载时机。
- **Quarto website / listing / `{{< embed >}}` / `{{< include >}}` / book / dashboard**：都无法表达「单入口切换多份已渲染的自包含报告」——`embed`/`include` 在渲染期解析而非运行期，website/book 天然产出多页。
- **手写 `index.html` 周清单**：与既有决策「入口页由脚本生成」冲突，清单会漂。

## 实测（本地 Playwright，cache disabled）

报告请求数：

| 场景 | 请求数 |
| --- | --- |
| 进入页面 | 1（自动加载最新一周） |
| 再选第 4 周 | 2 |
| 再选第 7 周 | 3 |
| 切回第 1、第 4 周 | 3 → 3（零请求） |

> 上表是最终口径。中间版本曾实现过「首屏 0 请求、全空等待用户选择」，该口径已被维护者否决（站点打开就该有内容），故不再列入。

其余断言：

- 进入页面：恰好 1 个 iframe、1 份报告请求（最新周），不是 7 份全量。
- 顶栏：`position: fixed`、高 44px、子元素垂直居中对齐且未换行、显示当前周与生成信息；唤出按钮无可见文字、含 SVG、保留 `aria-label`。
- 悬浮提示：悬停 100ms 与 250ms 时 `opacity` 仍为 0，约 411ms 后显示；快速扫过不弹出；键盘聚焦约 12–25ms 即显示；底色 `rgb(51,51,51)`。全页 17 个元素带提示。
- 内容区：紧贴顶栏（`top` 44 = 顶栏高）、零 padding、横向铺满；iframe 零边框零内边距。
- 抽屉：按钮打开 / 遮罩关闭 / `Esc` 关闭 / 选中后自动收起；打开时焦点移入抽屉，关闭后回到唤出按钮。
- 375px 窄屏：文档与 body 均无水平溢出、顶栏不溢出、抽屉宽 330px（88vw）覆盖内容不出界；加载报告后仍无水平滚动。
- 产物：`index.html` 为 LF-only，两次运行逐字节一致。

传输体积：单周原始 3.38–5.73 MiB；Vercel 实测协商到 brotli（`Content-Encoding: br`，单周 3.31 MiB）与 gzip（3.34 MiB），七周合计原始 28.47 MiB / gzip 14.39 MiB。

Vercel 对 HTML 返回 `cache-control: public, max-age=0, must-revalidate`：即使命中也走条件请求。
因此「已看过的周切回零请求」不能依赖缓存，只能靠面板留在 DOM 里——这正是每周一个常驻 iframe（而不是单个 iframe 换 `src`）的理由。

## 影响

- 契约新增：入口页输入固定名 `assets/site/index.template.html` / `hub.css` / `hub.js` 与四个占位符；`code/update_site.R` 在注入前校验「模板缺占位符 / 有未知占位符 / 占位符重复出现」并直接报错。已同步 [../docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md)、[../../weeks/README.md](../../weeks/README.md)、[../../code/README.md](../../code/README.md)、[../../README.md](../../README.md)、[../../AGENTS.md](../../AGENTS.md)。
- 写文件必须走二进制连接（`file(..., "wb")` + `writeBin`）：R 的默认文本连接在 Windows 把 `\n` 翻成 CRLF、在 Linux CI 写 LF。首次 CI 回写时因此把整份 `index.html` 重写一遍（368 行全变）。改为二进制写 LF 并保留结尾换行后，本地与 CI 产物逐字节一致。
- 不再把「本地双击 `file://`」当硬约束（目标改为远程 Vercel）；按需加载在 `file://` 下亦实测可用。
- 布局以内容区最大化为准：顶栏固定 44px 单行，周列表进默认收起的悬浮抽屉（点遮罩 / `Esc` / 选中后自动收起），`iframe` 铺满其余区域且零 padding / border / margin；页脚移除，原页脚的「共 N 周 / 生成于」并入顶栏右侧次要信息。
- **默认加载口径反转（重要）**：进入页面即加载**最新一周**（列表首项 = 目录名最大），不再是「首屏零请求」。这是维护者的明确要求——站点打开就该有内容，而不是空白等操作。其余周仍需主动选择才加载，「切回零请求」不变。契约文档已同步改写。
- 顶栏与列表里的按钮一律纯 SVG 图标，不写可见文字；文字改由悬浮提示承载（`data-tip`，黑框 `#333`、4px 圆角，对齐报告内 tippy 观感）。悬停延迟 400ms 出现、80ms 宽限后消失（鼠标扫过相邻元素不闪断）；键盘聚焦立即出现。`aria-label` 全部保留——提示是鼠标增强，不是无障碍替代。
- **身份分层（纠正「像官方站」的观感）**：原先顶栏唯一品牌字是 `TidyTuesday`（官方项目名）占作者位，而 `zlZayn` 在可见文字里 0 处出现，读起来像本站即官方。现改为三层各归其位——主题＝字标「TidyTuesday 可视化」；作者只在八爪鱼/仓库链接的悬浮提示（`zlZayn/tidytuesday`）与 `<title>` 里；来源由各周报告自身的 `TidyTuesday · 日期` 副标题承担，入口页不重复声明。
- **生成信息挪位与去字符分隔**：`N 周 · 生成于 日期` 原在顶栏右侧，紧邻「2026-09-15 标题」会被读成同一周的日期。现拆成两处——周数走抽屉顶部的 `.chip` 小标签，生成日期另起一行写「生成于 …」，位置在抽屉内。同时清掉 HTML/JS 里用 `·` 拼分隔的写法，间距改由 CSS `margin` 给。
- **设计令牌集中**：字号收敛为五档（品牌/正文/提示/元信息/微标）、图标尺寸两档，全部定义在 `hub.css` 顶部；SVG 不再写 `width`/`height`（原先两处八爪鱼各写各的，易漂）。审计确认无声明未使用的变量。
- **对比度修正**：`--hub-faint` 原为 `.55`，对白底仅 3.09:1，而它承载 11–12px 的日期与「生成于」，低于 WCAG AA 的 4.5:1。二分求解得最小合格值 `.70`（实测 4.62:1），故改为 `.70`。
- 视觉不新增设计语言：复用报告自身 cosmo 主题的令牌——字体栈（`"Source Sans Pro", -apple-system, "Segoe UI", …`）、前景 `#373a3c`、弱化色 `rgba(55,58,60,.75)`、边框 `#e1e1e1`、三级底 `#f8f9fa`、圆角 6px / 8px、强调色 `#2780e3`；品牌文字沿用 [assets/styles.css](../../assets/styles.css) 的 `h1.title` 七色渐变。
- 无障碍：唤出按钮带 `aria-label` 与 `aria-expanded`，抽屉 `role="dialog"` + `aria-modal` + `aria-labelledby`，打开时焦点移入（优先当前周，其次第一个周次），关闭时焦点回到唤出按钮，`Tab` 在抽屉内循环，`Esc` 关闭，快捷键 `m` 唤出。
- 已知遗留（与本次改动无关）：`weeks/2026-08-04/output/02_exploratory_visualization.html` 自带一个运行期 JS 报错（`i.map is not a function`，位于其内嵌 plotly 代码 `getScales`），单独打开该报告同样复现。

## 一处必须记住的实现约束

抽屉的 `visibility` 不能参与有时长的过渡（`transition: visibility .24s`）。它一旦延迟生效，打开瞬间元素仍是 `visibility: hidden`，而 hidden 元素无法获得焦点——`element.focus()` 会静默失败，表现为「点了按钮但焦点还在按钮上」。

正确写法：`transition: transform .24s, visibility 0s`（打开方向瞬时可见），关闭方向用 `visibility 0s linear .24s` 延迟到滑出动画结束才隐藏。该坑已记入根 [AGENTS.md](../../AGENTS.md) 活跃坑。
