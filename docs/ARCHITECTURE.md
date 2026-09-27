# tidytuesday 架构说明

## 设计目标

- 每周一个完整闭环：取数 → 数据检查 → 探索性可视化 → 单文件 HTML 归档 → 自动部署展示。
- 周与周隔离：某周的依赖、改动与产物不影响历史周。
- 产物可移植：单文件 HTML 自带样式与字体，本地双击与线上展示一致。

## 不可破坏的约束

- 周目录命名 `weeks/<YYYY-MM-DD>/`：字符串排序等价时间排序，站点据此取最新周。
- 产物固定名：`output/02_exploratory_visualization.html` 优先，缺失时回退 `output/01_data_check.html`；`code/update_site.R` 只认这两个名字。
- 入口页输入固定名：`assets/site/index.template.html`、`assets/site/hub.css`、`assets/site/hub.js`；三者的占位符契约见「设计要点」。
- 原始数据只读：`weeks/<date>/data/*.csv` 是下载快照，清洗结果另写 `output/<name>_cleaned.csv`。
- 图表文字用英文：R 渲染中文易缺字体。
- 路径不写死：样式统一 `../../../assets/styles.css`；数据路径按 qmd 类型解析（参数化模板靠 `assets/` 根标记定位项目根，手写 qmd 用 `../data/`），与运行位置无关。

## 数据流

1. `code/fetch_tt.R [日期]` 经 `tidytuesdayR` 下载 → `weeks/<date>/data/<dataset>.csv`。
2. `01_data_check.qmd`（`params$week` 指定周次）→ 7 步质量检查 + 清洗审计 + 整洁演示 → `output/01_data_check.html` 与 `output/<dataset>_cleaned.csv`。
3. `02_exploratory_visualization.qmd` → 图表与解读 → `output/02_exploratory_visualization.html`。
4. `code/update_site.R` 扫描各周产物（02 优先、回退 01）→ 读 `assets/site/` 下的模板与静态资源 → 占位符替换生成根 `index.html`（只做「外壳」：薄顶栏 + 唤出式抽屉列周，进页面即展示最新一周）。
5. `.github/workflows/deploy.yml`：push 到 main → CI 重跑 `update_site.R` → 有变化则把 `index.html` commit 回 main → Vercel 经 Git 集成自动部署整仓。

## 设计要点

- 输出目录固化在 `weeks/<date>/code/_quarto.yml` 的 `output-dir: ../output`（相对配置文件目录解析），渲染命令与运行位置解耦。
- 数据检查与可视化拆两个 qmd：质量报告与数据故事职责分离，一份失败不影响另一份。
- `01_data_check.qmd` 是参数化通用模板：六周共用同一份检查逻辑，只改 `params$week`。
- 入口页由脚本生成而非手写：新增周不改 HTML，避免手写清单漂移。
- 入口页是「薄外壳」+ 按需加载：进页面即加载**最新一周**（仅这一份请求），其余周选中才创建该周 iframe 并设 `src`（单周 gzip 后 1.4–3.3 MiB，全量 7 周约 14 MiB）。已创建的面板留在 DOM 中切显隐，切回零请求。
- 入口页把自身 UI 压到最小、内容区最大化：顶栏固定 44px 单行，周列表放在默认收起的悬浮抽屉里（点遮罩 / `Esc` / 选中后自动收起），`iframe` 铺满顶栏以下区域且无 padding / border / margin。视觉沿用报告自身的 cosmo 令牌（字体栈、`#373a3c` 前景、`#e1e1e1` 边框、6px 圆角、`#2780e3` 强调色）与 `assets/styles.css` 的品牌渐变，不引入第二套设计语言。
- 身份分三层且各归其位：**主题**是顶栏字标「TidyTuesday 可视化」（本站是对官方数据的个人练习，字标里不写「官方」也不写作者名）；**作者**只在八爪鱼图标与仓库链接的悬浮提示里出现；**来源**由各周报告自身的 `TidyTuesday · 日期` 副标题承担，入口页不重复声明。`<title>` 保留作者名，供标签页与书签识别。
- 顶栏与抽屉的图标按钮一律纯 SVG、不写可见文字，文字由 `data-tip` 悬浮提示承载（黑框 `#333`、4px 圆角，对齐报告内 tippy 观感）；悬停延迟约 400ms 出现、键盘聚焦立即出现。尺寸与字号集中在 `hub.css` 顶部的变量里（字号五档、图标尺寸两档），SVG 不写 `width`/`height`，避免同一图标在两处大小不一。
- 文本不用 `·` 这类字符做分隔：周数与生成日期分别走 `.chip` 小标签与独立一行，日期与标题之间的间距由 CSS 的 `margin` 给。生成日期放在抽屉顶部而不是顶栏，避免被读成某一周的日期。
- 弱化文字色 `--hub-faint` 的透明度不得低于 `.70`：它大量用于 11–12px 的日期与「生成于」，`.55` 时对白底仅 3.09:1，低于 WCAG AA 的 4.5:1；`.70` 实测 4.62:1 才合格。
- 抽屉的 `visibility` 必须瞬时生效（`transition: visibility 0s`，仅关闭方向给延迟）：它一旦参与时长过渡，打开瞬间元素仍是 `hidden`，而 hidden 元素无法获得焦点，焦点移入抽屉会静默失败。
- 入口页样式与脚本不直接对外：`assets/site/index.template.html` 里的 `@@HUB_CSS@@` / `@@HUB_DATA@@` / `@@HUB_JS@@` / `@@REPO_URL@@` 由 `update_site.R` 做固定字符串替换；占位符用 at-at 包裹而非双花括号，避免与 CSS/JS 的花括号混淆。
- 不用 `loading="lazy"` 决定是否加载：实测面板为一屏高时 7 个 iframe 仍全部立即加载，只有面板远高于视口才延迟，行为取决于浏览器视口距离阈值，不可控。
- 每周报告之间不能直接拼接 DOM：七份报告各自自带 Bootstrap + Quarto 样式，且跨周重复 10 个元素 id（`quarto-content`、`quarto-document-content`、`TOC`、`toc-title`、`title-block-header` 等）与 2 个 `link/style` id，拼接必然冲突。iframe 是唯一可行的隔离手段。
- 根目录标记物 `assets/` 用于向上定位项目根，兼容工作目录与文件名的差异。
- 六周 02 可视化共用一个工艺底线 `assets/tt_theme.R`（字号阶梯、家族上限、导出参数、重量预算、零件函数），但视觉身份逐周独立——调色板与图表家族由各周 qmd 自带，共享文件不含各周调色板（`tt_base()` 仅中性兜底默认色）。
- 报告不展示源码、不展示内部笔记：报告 chunk 一律 `echo: false`（含绘图块），自检块另加 `include: false`，`stopifnot` 硬闸保留，判定只写渲染日志。
- 页面重量按 MiB 设预算：单页 ≤ 6、单张内嵌 PNG ≤ 2；超预算先降大画幅图的 `fig-dpi`（下限 160），再减画布或分层。

## 防错清单

- 改 `update_site.R` 的扫描文件名或周目录命名规则 → 必须同步每周产物名、[../weeks/README.md](../weeks/README.md) 硬编码约定段与本文件。
- 改 `assets/site/` 三个文件名或模板占位符 → 必须同步 `update_site.R` 顶部的固定名常量与本文件；脚本会在注入前校验「模板缺占位符 / 有未知占位符」并直接报错。
- 只渲染 01 的周会以带「数据检查」标记的条目进列表：站点不漏周，但访客看到的是数据检查而非可视化。
- 根 `index.html` 由 CI 每次 push 重写：本地手改会被覆盖，展示逻辑改 `update_site.R` 与 `assets/site/`。
- 不要在任何 iframe 的 `load` 回调里 `replaceChildren` / 移除该 iframe：会触发重复加载甚至无限重载循环；提示层只用 `hidden` 切换，iframe 节点保持不动。
- 托管由 Vercel 承担，GitHub Actions 不参与部署：workflow 只负责生成并 commit `index.html`，本仓不引入任何 Pages 相关 action。
- 改 `assets/tt_theme.R` 是共享依赖变更，广播与重渲染要求见根 [AGENTS.md](../AGENTS.md) 活跃坑。
- 本地 R 4.6.0 与 CI R 4.3 并存：CI 只跑 base R 脚本，不引入第三方包才能保持等价。
- 渲染成功不等于数据到位：`data/` 为空时 01 报告会在周级汇总处报错中断（`count()` 找不到列）。
