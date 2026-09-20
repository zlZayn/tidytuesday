# assets/ — 共享样式资源

- 职责：跨周复用的主题样式与字体。
- `styles.css`：渐变标题、平滑 TOC、MapleMono 字体声明；由各周 qmd 的 YAML `format.html.css: ../../../assets/styles.css` 引用。
- `MapleMono[wght]-VF.ttf`：等宽字体，由 `styles.css` 引用；`self-contained: true` 渲染时内嵌进单文件 HTML。
- `tt_theme.R`：六周 02 可视化的共享工艺底线——字号阶梯 `TT_TYPE`、家族上限 `TT_FAMILY_MAX`、导出参数 `TT_EXPORT`、重量预算 `TT_PNG_MAX_MB` / `TT_HTML_MAX_MB` / `TT_DPI_FLOOR`、禁用清单，以及零件 `tt_base()` / `tt_strip()` / `tt_source()` / `tt_flow()` / `tt_audit()` / `tt_weigh()`；由各周 `02_exploratory_visualization.qmd` 以 `source()` 载入。调色板不进本文件，由各周 qmd 自带。
- 变更影响路由：改 `styles.css` 后重渲染受影响周核对产物，改文件名同步所有 qmd 的 `css:` 路径与 [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)；改 `tt_theme.R` 属共享依赖变更，要求见根 [AGENTS.md](../AGENTS.md) 活跃坑。
- 使用约束与工作偏好 → 见 [AGENTS.md](AGENTS.md)。
