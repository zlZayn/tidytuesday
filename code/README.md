# code/ — 取数与站点生成

- 职责：跨周复用的两个脚本，不随周变化。
- `fetch_tt.R`：下载指定周（缺省今天）的 TidyTuesday 数据到 `weeks/<date>/data/<dataset>.csv`，官方说明写 `weeks/<date>/readme.md`；依赖 `tidytuesdayR`（下载）与 `readr`（写 CSV）；是每周流程的第一步。
- `update_site.R`：扫描 `weeks/<date>/output/`（`02_exploratory_visualization.html` 优先，缺失时回退 `01_data_check.html`），按目录名降序生成根 `index.html`（侧边栏列出全部周 + iframe 默认最新周）；纯 base R，无第三方依赖；由 [../.github/workflows/deploy.yml](../.github/workflows/deploy.yml) 在每次 push 后重跑。
- 变更影响路由：改产物文件名或周目录命名 → 同步 [../weeks/README.md](../weeks/README.md) 的硬编码约定段与 [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) 防错清单；改依赖 → 同步 CI 与根 [AGENTS.md](../AGENTS.md) 验证快照。
- 使用约束与工作偏好 → 见 [AGENTS.md](AGENTS.md)。
