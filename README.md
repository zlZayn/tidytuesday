# tidytuesday

[![Check site entry page](https://github.com/zlZayn/tidytuesday/actions/workflows/deploy.yml/badge.svg)](https://github.com/zlZayn/tidytuesday/actions)

每周一份 TidyTuesday 数据报告：先做**数据检查**，再做**探索性可视化**，各自归档成可单文件分享的 HTML，并汇入一个按周切换的在线站点。

**在线浏览 → <https://tidytuesday-taupe.vercel.app>**

## 数据从哪来

TidyTuesday 每周二发布一份开放数据集（[官方仓库](https://github.com/rfordatascience/tidytuesday)）。本项目按下发日期建目录、原样保存 CSV，周与周之间互不影响。

## 每周产出两份报告

| 报告 | 回答的问题 | 内容 |
| --- | --- | --- |
| `01_data_check` | 这份数据**能不能用** | 七步确定性质量检查（结构、缺失与重复、基数、分布、相关性）+ 清洗审计与处理日志 + 周级汇总 |
| `02_exploratory_visualization` | 这份数据**说明了什么** | 本周选题的图表与解读，每图配标题、口径副标题与来源脚注 |

两份都是 `self-contained` 单文件 HTML，样式与字体内嵌，双击即看，也可直接分享。

## 在哪看

站点进入即展示最新一周，顶栏左侧图标唤出周次抽屉（快捷键 <kbd>M</kbd>）；选中哪一周才加载哪一周，已看过的周切回不重复下载。

## 快速开始

```bash
Rscript code/fetch_tt.R              # 取最近一周数据
Rscript code/fetch_tt.R 2026-09-29   # 或指定日期
```

取完在 `weeks/<date>/code/` 写 qmd 并 `quarto render`。完整流程与模板见 [weeks/README.md](weeks/README.md)。

## 环境

- R
- `tidytuesdayR` — 取数
- Quarto CLI — 渲染 qmd

各周报告还会用到绘图与制表包，按需安装；清单在各周 `code/*.qmd` 的 setup 块里。

## 说明

- 站点入口页 `index.html` 由 `code/update_site.R` 生成，不手改。
- 本站是对官方数据的个人练习，非官方项目。
- 未附 License：仓库不对外发布，也不需要。

维护者文档地图见 [AGENTS.md](AGENTS.md)，设计与契约见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。
