# code/ — 取数与站点生成

- 职责：跨周复用的三个脚本，不随周变化。
- `fetch_tt.R`：下载指定周（缺省今天）的 TidyTuesday 数据到 `weeks/<date>/data/<dataset>.csv`，官方说明写 `weeks/<date>/readme.md`；依赖 `tidytuesdayR`（下载）与 `readr`（写 CSV）；是每周流程的第一步。
- `update_site.R`：扫描 `weeks/<date>/output/`（`02_exploratory_visualization.html` 优先，缺失时回退 `01_data_check.html`），按目录名降序读 [../assets/site/](../assets/site/) 下的模板与静态资源，做占位符替换生成根 `index.html`（薄顶栏 + 默认收起的周次抽屉；进入页面自动加载最新一周，其余周选中才加载）；纯 base R，无第三方依赖。
- `check_site_index.py`：只校验不生成——核对 `index.html` 的周列表与 `weeks/` 实际产物是否一致（周、顺序、`src` 可解析、`kind` 正确）；纯标准库、无网络，约 140 ms；由 [../.github/workflows/deploy.yml](../.github/workflows/deploy.yml) 在每次 push 后运行，不同步即红叉。生成由本地 [../.githooks/pre-commit](../.githooks/pre-commit) 负责，CI 不再重跑 `update_site.R`。
- 依赖：`fetch_tt.R` 用 `tidytuesdayR`（下载）与 `readr`（写 CSV）；另外两个脚本纯 base R / 标准库。
- 变更影响路由：改产物文件名或周目录命名 → 同步 [../weeks/README.md](../weeks/README.md) 的硬编码约定段与 [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) 防错清单；改 `assets/site/` 的文件名或占位符 → 同步本脚本顶部的固定名常量；改依赖 → 同步 CI 与根 [AGENTS.md](../AGENTS.md) 验证快照。
- 使用约束与工作偏好 → 见 [AGENTS.md](AGENTS.md)。
