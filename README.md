# tidytuesday

个人 TidyTuesday 参与项目：每周拉取官方数据，用 R 做数据检查与可视化，以 Quarto 产出报告并长期积累。本文档是项目入口，说明目录结构与环境要求；每周的流程、模板与约定见 [weeks/README.md](weeks/README.md)。

## 目录结构

```txt
tidytuesday/
├── README.md                # 项目入口文档（本文件）
├── assets/                  # 共享样式资源（跨周复用）
│   ├── styles.css           # 主题样式：渐变标题 + 平滑 TOC + MapleMono
│   └── MapleMono[wght]-VF.ttf   # 等宽字体（styles.css 引用）
├── code/                    # 可复用代码（不随周变化）
│   └── fetch_tt.R           # 通用取数脚本，参数化日期
└── weeks/                   # 每周一个独立目录，互不干扰
    ├── README.md            # 每周流程 / qmd 模板 / 约定（见上）
    └── 2026-08-04/          # 以日期命名，长期积累清晰
        ├── code/            # 该周分析文档（qmd）
        │   ├── _quarto.yml                      # 固化输出目录（output-dir: ../output）
        │   ├── 01_data_check.qmd               # 数据检查（7 步质量检查）
        │   └── 02_exploratory_visualization.qmd # 探索性可视化（图表 + 解读）
        ├── data/            # 原始数据（CSV）
        ├── output/          # 渲染产物（单文件 HTML）
        └── readme.md        # 该周官方说明
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
