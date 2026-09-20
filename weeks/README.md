# weeks/ — 每周流程与约定

本目录存放每周 TidyTuesday 工作区。以下为**每周重复的流程、模板与习惯约定**（参考性质，非强制）。

规则层（进入本目录时自动注入）见 [AGENTS.md](AGENTS.md)；设计与契约见 [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)。

## 每周流程

以项目根目录作为工作目录打开（RStudio/VSCode 直接打开项目文件夹）。

1. 拉取数据（自动落到 `weeks/<date>/data/`）：

   ```bash
   Rscript code/fetch_tt.R              # 默认最近一周
   Rscript code/fetch_tt.R 2026-08-04   # 指定日期
   ```

2. 在 `weeks/<date>/code/` 下创建 `_quarto.yml`（固化输出目录，渲染无需 `--output-dir`），再新建 qmd。默认拆分两个（数据检查 + 可视化），也可合并或调整，参考下方模板。

   ```yaml
   # weeks/<date>/code/_quarto.yml
   project:
     output-dir: ../output
   ```

   > `output-dir` 相对 `_quarto.yml` 所在目录解析，输出始终指向 `weeks/<date>/output/`，与运行位置无关。

3. 渲染两个 qmd（每个生成独立 HTML，无需 `--output-dir`）：

   ```bash
   quarto render 01_data_check.qmd
   quarto render 02_exploratory_visualization.qmd
   ```

   产物为单文件 HTML，输出到 `weeks/<date>/output/`。

### 渲染注意事项

| 事项 | 说明 |
| --- | --- |
| 必须两个都渲染 | `01_data_check` 和 `02_exploratory_visualization` 各自生成独立 HTML，一个不跑就少一份 |
| 输出目录已固化 | `_quarto.yml` 的 `output-dir: ../output` 管住输出位置，任意目录跑都落到 `weeks/<date>/output/` |
| qmd 内部路径自动解析 | 图片 `images/`、样式 `../../../assets/` 相对 qmd 文件本身；数据路径见「常用约定」的数据读取行。渲染与运行位置无关 |
| 渲染失败排查 | 报 `there is no package` → 装对应包；报字体路径 → `css: ../../../assets/styles.css` 检查层级；改了代码没变化 → 重跑（quarto 无强缓存） |
| 增量渲染 | 只改了内容想快速预览：`quarto render 02_exploratory_visualization.qmd` 单跑即可 |

> 提示：`tidytuesdayR` 只下载数据文件。如需该周配套材料（`intro.md`、`cleaning.R`、`meta.yaml`），直接从 GitHub 拉取：
> `https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/<年>/<日期>/<文件名>`

## qmd 模板（参考）

参考做法：拆两个 qmd，职责分离——`01_data_check.qmd` 报告数据质量（结构/缺失/基数/相关性），`02_exploratory_visualization.qmd` 讲数据故事（图表 + 解读）。**模板与拆分均非强制**，每周按需套用、合并或增删。文件名与 title 语义对应（英文 snake_case ↔ 中文标题）。

YAML 模板（`<周主题>`、`<日期>`、`<周数>` 按每周替换；`css` 路径为 qmd 所在 `code/` 到根目录的相对路径）：

```yaml
---
title: "<周主题> 数据检查"                        # 02 文件改为 "<周主题> 探索性可视化"
subtitle: "TidyTuesday · <日期> (Week <周数>)"
author: "zlZayn"
date: today
format:
  html:
    css: ../../../assets/styles.css
    highlight-style: tango
    toc: true
    toc-expand: true
    toc-depth: 3
    toc-location: left
    code-fold: true
    theme: cosmo
    grid:
      sidebar-width: 350px
      body-width: 900px
      margin-width: 150px
      gutter-width: 1.5em
    lang: zh
    self-contained: true
execute:
  warning: false
  message: false
---
```

> `code-fold` 只在存在 `echo: true` 的 chunk 时才生效；本项目报告 chunk 一律 `#| echo: false`，页面不展示 R 源码。验收判据：产物中 `<pre` 与 `class="sourceCode` 计数为 0（精确匹配 `class="sourceCode"` 会假阴性：Quarto 写的是带后缀形式，如 `class="sourceCode cell-code"` / `class="sourceCode r code-with-copy"`）。

## 常用约定

| 项 | 约定 |
| --- | --- |
| 文件命名 | 文件名 = title 的英文 snake_case：`01_data_check`、`02_exploratory_visualization` |
| YAML | 各 qmd 尽量同构，只改 `title` 与 `subtitle` |
| 样式 | 共用根目录 `assets/styles.css`（含 MapleMono 字体），self-contained 自动内嵌 |
| 输出 | `self-contained: true`，单文件 HTML，便于分享与归档 |
| 数据读取 | 手写 qmd 用相对路径 `../data/<dataset>.csv`（相对 `weeks/<date>/code/`）；参数化模板 `01_data_check.qmd` 例外——用 `assets/` 根标记定位项目根后拼 `weeks/<week>/data/` |
| 图表 | 每图配 cell 选项 `#&#124; label: fig-*`、`#&#124; fig-cap:`，可交叉引用 |
| 语言 | **图内文字一律英文**（原因见 [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)）；正文 / 表格注释可为中文 |

## 自动部署（GitHub Pages）

push 到 `main` 后，Actions 自动部署到 <https://zlzayn.github.io/tidytuesday/>：
入口页（index.html）侧边栏列出所有周，iframe 默认展示最新周可视化；点击某周在新标签打开该周报告，同时切换入口页的 iframe 预览；头部 GitHub 图标 + 用户名跳转仓库。

**脚本与模板的配合关系**（`code/update_site.R` 与每周 qmd 模板互相依赖）：

| 环节 | 谁负责 | 说明 |
| --- | --- | --- |
| 产出可视化 | 每周 qmd 模板 | 渲染 `02_exploratory_visualization.qmd` 得到同名 HTML |
| 收录全部周 | `update_site.R` | 优先 `02_exploratory_visualization.html`，缺失时回退 `01_data_check.html`（条目带「数据检查」标记）；两个都没有的周不进列表 |
| 排序与默认 | `update_site.R` | 按目录名降序（新 → 旧）进侧边栏，最新周为 iframe 默认内容 |
| 默认展示 | `update_site.R` | 取日期最大的周作为 iframe 默认内容 |
| 历史列表 | `update_site.R` | 其余周按日期降序进侧边栏 |

**硬编码约定**（改动任一侧都会破坏部署，必须同步改）：

1. 产物固定名（优先级从高到低）：`weeks/<date>/output/02_exploratory_visualization.html` → `weeks/<date>/output/01_data_check.html`
   - 脚本只认这两个文件名，不猜、不改名
2. 周目录命名：`weeks/<YYYY-MM-DD>/`
   - 字符串排序 = 时间排序，最新周 = 目录名最大的
3. 每周只需两步：渲染出 `02_exploratory_visualization.html`（该周没有就先渲染 `01_data_check.html`）→ push
   - 下次部署自动重扫目录，无需改脚本

**一句话流程**：每周渲染出固定文件名的 HTML → push → Actions 重跑 `update_site.R` → 重扫目录 → 全部周按新 → 旧进侧边栏，最新周成为默认展示。
