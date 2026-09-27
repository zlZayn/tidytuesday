# tidytuesday

个人 TidyTuesday 参与项目：每周拉取官方数据，用 R 做数据检查与可视化，以 Quarto 产出报告并长期积累。本文档是项目入口，说明目录结构与环境要求；每周的流程、模板与约定见 [weeks/README.md](weeks/README.md)。

数据来自官方 [TidyTuesday 仓库](https://github.com/rfordatascience/tidytuesday)（每周二发布）。

**在线浏览 → <https://tidytuesday-taupe.vercel.app>**

站点入口页**进入即展示最新一周**（只请求这一份），其余周在顶栏左侧图标按钮唤出的抽屉里按新 → 旧列出（快捷键 <kbd>M</kbd>）；选中某周才加载那一周（单周 gzip 后约 1.4–3.3 MiB），已看过的周切回不重新下载。

## 目录结构

```txt
tidytuesday/
├── README.md                # 项目入口文档（本文件）
├── index.html               # 站点入口页（自动生成：顶栏 + 抽屉列周，选中才加载该周）
├── assets/                  # 共享样式资源（跨周复用）
│   ├── styles.css           # 主题样式：渐变标题 + 平滑 TOC + MapleMono（各周报告用）
│   ├── MapleMono[wght]-VF.ttf   # 等宽字体（styles.css 引用）
│   └── site/                # 入口页骨架（由 update_site.R 内联进根 index.html）
│       ├── index.template.html  # 入口页模板（含 @@HUB_*@@ 占位符）
│       ├── hub.css          # 入口页样式
│       └── hub.js           # 入口页 tab 与按需加载逻辑
├── code/                    # 可复用代码（不随周变化）
│   ├── fetch_tt.R           # 通用取数脚本，参数化日期
│   └── update_site.R        # 生成入口页 index.html（扫描 weeks/ + 替换模板占位符）
├── .github/workflows/       # GitHub Actions（push 到 main 重生成入口页并 commit 回 main）
│   └── deploy.yml           # 生成 + commit 工作流（部署由 Vercel 负责）
└── weeks/                   # 每周一个独立目录，互不干扰
    ├── README.md            # 每周流程 / qmd 模板 / 约定（见上）
    └── <YYYY-MM-DD>/        # 以日期命名，长期积累清晰
        ├── code/            # 本周 qmd 与周内资源（图片、图标）
        │   ├── _quarto.yml      # 固化输出目录（output-dir: ../output）
        │   └── *.qmd            # 本周分析文档（数据检查 / 可视化）
        ├── data/            # 原始数据（CSV，只读）
        └── output/          # 渲染产物（单文件 HTML + 清洗后 CSV）
```

设计原则：

| 原则 | 体现 |
| --- | --- |
| 隔离 | 每周数据、代码、产出放在各自 `weeks/<date>/` 下，互不污染 |
| 可复用 | 取数逻辑收敛在 `code/fetch_tt.R`；qmd 模板在 `weeks/README.md` 可直接套用 |
| 灵活 | 模板仅供参考，不强制——每周按需调整文件拆分与内容 |
| 可移植 | 路径相对项目根或当前周目录，不写死绝对路径 |

## 快速开始

```bash
# 拉取最近一周数据
Rscript code/fetch_tt.R

# 新建周目录后，按 weeks/README.md 的模板写 qmd 并渲染
```

每周完整流程、qmd YAML 模板与语言约定见 **[weeks/README.md](weeks/README.md)**。

## 环境要求

- R >= 4.x
- tidytuesdayR（dev 版，含最新周映射）：`remotes::install_github("dslc-io/tidytuesdayR")`
- readr、dplyr、tidyr、purrr、stringr、ggplot2、scales
- Quarto CLI（渲染 qmd）
- 交互式表格（可视化 qmd 可选）：reactable、reactablefmtr、dataui、htmltools、htmlwidgets、glue、base64enc
- 可视化增强（`02_exploratory_visualization.qmd` 已用）：ggtext、ggimage、magick

## 维护

维护索引与文档地图见 [AGENTS.md](AGENTS.md)；设计与契约见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。
