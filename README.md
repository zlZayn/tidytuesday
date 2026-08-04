# tidytuesday

个人 TidyTuesday 参与项目。每周拉取数据、做分析、产出图表。

## 目录结构

```
tidytuesday/
├── README.md              # 项目说明
├── code/                  # 可复用代码（不随周变化）
│   └── fetch_tt.R         # 通用取数脚本，参数化日期
└── weeks/                 # 每周一个独立目录，互不干扰
    └── 2026-08-04/        # 以日期命名，长期积累清晰
        ├── data/          # 原始数据（CSV）
        ├── readme.md      # 该周官方说明
        └── output/        # 该周分析产出（图表/报告）
```

设计原则：

| 原则 | 体现 |
| --- | --- |
| 隔离 | 每周数据、说明、产出放在各自 `weeks/<date>/` 下，互不污染 |
| 可复用 | 取数逻辑收敛在 `code/fetch_tt.R`，每周不重复写 |
| 长期积累 | 按日期命名，历史周一目了然，可随时回看 |
| 可移植 | 所有路径相对项目根目录，不写死绝对路径 |

## 使用方式

以项目根目录 `D:\RDirectory\tidytuesday` 作为工作目录打开（RStudio/VSCode 直接打开该文件夹）。

### 拉取某周数据

```bash
# 默认取最近一周
Rscript code/fetch_tt.R

# 指定日期
Rscript code/fetch_tt.R 2026-08-04
```

数据落到 `weeks/2026-08-04/data/`，官方说明存到 `weeks/2026-08-04/readme.md`。

### 每周分析流程

1. 运行取数脚本拉数据
2. 在 `weeks/<date>/` 下新建分析脚本（如 `analysis.R`），读取 `data/<dataset>.csv`
3. 图表/报告输出到 `weeks/<date>/output/`
4. （可选）每周主题记录在 `weeks/<date>/readme.md` 或根 README 补充

## 环境要求

- R >= 4.x
- tidytuesdayR（dev 版，含最新周映射）：`remotes::install_github("dslc-io/tidytuesdayR")`
- readr
