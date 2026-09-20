# tidytuesday 架构说明

## 设计目标
- 每周一个完整闭环：取数 → 数据检查 → 探索性可视化 → 单文件 HTML 归档 → 自动部署展示。
- 周与周隔离：某周的依赖、改动与产物不影响历史周。
- 产物可移植：单文件 HTML 自带样式与字体，本地双击与线上展示一致。

## 不可破坏的约束
- 周目录命名 `weeks/<YYYY-MM-DD>/`：字符串排序等价时间排序，站点据此取最新周。
- 产物固定名：`output/02_exploratory_visualization.html` 优先，缺失时回退 `output/01_data_check.html`；`code/update_site.R` 只认这两个名字。
- 原始数据只读：`weeks/<date>/data/*.csv` 是下载快照，清洗结果另写 `output/<name>_cleaned.csv`。
- 图表文字用英文：R 渲染中文易缺字体。
- 路径不写死：样式统一 `../../../assets/styles.css`；数据路径按 qmd 类型解析（参数化模板靠 `assets/` 根标记定位项目根，手写 qmd 用 `../data/`），与运行位置无关。

## 数据流
1. `code/fetch_tt.R [日期]` 经 `tidytuesdayR` 下载 → `weeks/<date>/data/<dataset>.csv`。
2. `01_data_check.qmd`（`params$week` 指定周次）→ 7 步质量检查 + 清洗审计 + 整洁演示 → `output/01_data_check.html` 与 `output/<dataset>_cleaned.csv`。
3. `02_exploratory_visualization.qmd` → 图表与解读 → `output/02_exploratory_visualization.html`。
4. `code/update_site.R` 扫描各周产物（02 优先、回退 01）→ 生成根 `index.html`（侧边栏按新 → 旧列出全部周 + iframe 默认最新周）。
5. `.github/workflows/deploy.yml`：push 到 main → CI 重跑 `update_site.R` → 整仓上传 GitHub Pages。

## 设计要点
- 输出目录固化在 `weeks/<date>/code/_quarto.yml` 的 `output-dir: ../output`（相对配置文件目录解析），渲染命令与运行位置解耦。
- 数据检查与可视化拆两个 qmd：质量报告与数据故事职责分离，一份失败不影响另一份。
- `01_data_check.qmd` 是参数化通用模板：六周共用同一份检查逻辑，只改 `params$week`。
- 入口页由脚本生成而非手写：新增周不改 HTML，避免手写清单漂移。
- 根目录标记物 `assets/` 用于向上定位项目根，兼容工作目录与文件名的差异。
- 六周 02 可视化共用一个工艺底线 `assets/tt_theme.R`（字号阶梯、家族上限、导出参数、重量预算、零件函数），但视觉身份逐周独立——调色板与图表家族由各周 qmd 自带，共享文件不含各周调色板（`tt_base()` 仅中性兜底默认色）。
- 报告不展示源码、不展示内部笔记：报告 chunk 一律 `echo: false`（含绘图块），自检块另加 `include: false`，`stopifnot` 硬闸保留，判定只写渲染日志。
- 页面重量按 MiB 设预算：单页 ≤ 6、单张内嵌 PNG ≤ 2；超预算先降大画幅图的 `fig-dpi`（下限 160），再减画布或分层。

## 防错清单
- 改 `update_site.R` 的扫描文件名或周目录命名规则 → 必须同步每周产物名、[../weeks/README.md](../weeks/README.md) 硬编码约定段与本文件。
- 只渲染 01 的周会以带「数据检查」标记的条目进侧边栏：站点不漏周，但访客看到的是数据检查而非可视化。
- 根 `index.html` 由 CI 每次 push 重写：本地手改会被覆盖，展示逻辑改 `update_site.R`。
- 改 `assets/tt_theme.R` 是共享依赖变更，广播与重渲染要求见根 [AGENTS.md](../AGENTS.md) 活跃坑。
- 本地 R 4.6.0 与 CI R 4.3 并存：CI 只跑 base R 脚本，不引入第三方包才能保持等价。
- 渲染成功不等于数据到位：`data/` 为空时 01 报告会在周级汇总处报错中断（`count()` 找不到列）。
