# weeks · 每周规范

本目录存放每周 TidyTuesday 工作区。以下为**每周重复的流程、模板与习惯约定**（参考性质，非强制）。

## 每周流程

以项目根目录 `D:\RDirectory\tidytuesday` 作为工作目录打开（RStudio/VSCode 直接打开该文件夹）。

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
| qmd 内部路径自动解析 | 数据 `../data/`、图片 `images/`、样式 `../../../assets/` 都相对 qmd 文件本身，与运行位置无关 |
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

## 常用约定

| 项 | 约定 |
| --- | --- |
| 文件命名 | 文件名 = title 的英文 snake_case：`01_data_check`、`02_exploratory_visualization` |
| YAML | 各 qmd 尽量同构，只改 `title` 与 `subtitle` |
| 样式 | 共用根目录 `assets/styles.css`（含 MapleMono 字体），self-contained 自动内嵌 |
| 输出 | `self-contained: true`，单文件 HTML，便于分享与归档 |
| 数据读取 | qmd 内用相对路径 `../data/<dataset>.csv`（相对 `weeks/<date>/code/`） |
| 图表 | 每图配 cell 选项 `#&#124; label: fig-*`、`#&#124; fig-cap:`，可交叉引用 |
| 语言 | **图内文字一律英文**（R 渲染中文易缺字体）；正文/表格注释可为中文 |
