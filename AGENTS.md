# tidytuesday — 维护索引

个人 TidyTuesday 项目：每周拉取官方数据，用 R / Quarto 产出数据检查与探索性可视化，push 后由 GitHub Actions 部署到 https://zlzayn.github.io/tidytuesday/。

## 全局规则（本项目特有）
- 每周工作区隔离：数据、代码、产物都在 `weeks/<YYYY-MM-DD>/` 内，跨周不共享文件。
- 契约不可单侧改动：可视化产物固定名 `02_exploratory_visualization.html`，周目录固定名 `YYYY-MM-DD`；细节见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。
- 图内文字一律英文（原因见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) 的不可破坏约束），正文与表格注释可用中文。
- 路径不写死：样式统一 `../../../assets/styles.css`；数据路径按 qmd 类型取——参数化模板 `01_data_check.qmd` 用 `assets/` 根标记定位项目根后拼 `weeks/<week>/data/`，手写 qmd 用 `../data/<dataset>.csv`。
- 事实只在 home 展开：访客向 → [README.md](README.md)，设计向 → [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)，每周流程 → [weeks/README.md](weeks/README.md)；规则层给规则与指针，不复制理由与步骤。

## 常用命令
- 取数：`Rscript code/fetch_tt.R [YYYY-MM-DD]`（缺省取今天；落到 `weeks/<date>/data/`）
- 渲染单周：在 `weeks/<date>/code/` 下执行 `quarto render 01_data_check.qmd`（`_quarto.yml` 已固化 `output-dir: ../output`）
- 生成站点入口页：`Rscript code/update_site.R`（CI 在 push 后自动重跑）
- 链接校验：`python "$env:USERPROFILE\.agents\skills\maintenance-flow\check-links.py" . --fragments --refs`
- 换行校验：`python "$env:USERPROFILE\.agents\skills\maintenance-flow\check-line-endings.py" .`（只读模式只报「单文件混用行尾」，当前 0 个；写入模式必须先限定范围，如 `--ext .md --ext .qmd --ext .yml --ext .R`）

## 验证快照
- 部署状态 → [Actions](https://github.com/zlZayn/tidytuesday/actions)（自更新来源，不抄数字）。
- 渲染验收（无 CI 覆盖，命令级）：`output/<name>.html` 存在且 > 1 MB；`output/<name>_cleaned.csv` 落盘；HTML 内含 8 个小节（Skeleton → 清洗审计与处理）与「周级整洁汇总」，且无 `there is no package` / `Execution halted` 字样。
- 本地工具链：R 4.6.0 · Quarto 1.9.37；CI 用 R 4.3，只跑 base R 脚本。
- 02 可视化验收：六周 `output/02_exploratory_visualization.html` 存在、单页 ≤ 6 MiB、单图 ≤ 2 MiB、图内文字英文、正文不含内部笔记与 R 源码；判据与替代方案见 [.agents/notes/2026-09-20-visual-identity-policy.md](.agents/notes/2026-09-20-visual-identity-policy.md)。

## 待办
- [ ] [weeks/README.md](weeks/README.md) YAML 模板里的 `code-fold: true` 只在 `echo: true` 的块上生效，待决定删行或保留。
- [ ] 根 README 门面缺徽章 / License / 贡献段：仓库暂无 LICENSE 文件，需先定许可证。
- [ ] `weeks/<date>/readme.md`（该周官方说明）一个都不存在：`code/fetch_tt.R` 只在拿到官方 readme 时才写，待确认是否补齐。
- [ ] `01_data_check.qmd` 的 title / subtitle 是通用文案，未按 [weeks/README.md](weeks/README.md) 模板填「<周主题>」与周数。
- [ ] `01_data_check.qmd` 对空 `data/` 的处置：加 `knitr::knit_exit()` 或改成显式报错（六个模板需同步）。

## 活跃坑
- 站点收录规则：`code/update_site.R` 优先 `output/02_exploratory_visualization.html`，缺失时回退 `output/01_data_check.html` 并标「数据检查」；只渲染 01 的周仍进侧边栏（展示的是数据检查）。
- `weeks/<date>/code/.gitignore` 由 Quarto 渲染时自动生成（`/.quarto/` 与 `**/*.quarto_ipynb`），不是手写文件。
- 根 `index.html` 由 CI 每次 push 重新生成：本地手改会被覆盖，要改展示逻辑就改 `code/update_site.R`。
- 周目录 `data/` 为空时 `01_data_check.qmd` 渲染会中断：setup 只 `cat` 一句警告，但「周级整洁汇总」的 `count()` 找不到列会报错（该 chunk 未设 `error: true`）。
- 行尾是两分现状，不追求统一：手写 `.md` / `.qmd` / `.yml` / `.R` 为 LF；`assets/styles.css`（手写例外）、`index.html`（脚本生成）与 Quarto 产物为 CRLF。工具的硬判据只有「单文件不得混用」；`--target lf --write` 不带 `--ext` 会改写全仓 23 个 CRLF 文件（HTML / CSS / .gitignore 三类 17 个，其中已提交 5 个；另 6 个是 `.quarto/_freeze` 缓存与 `debug_render.txt`，均未提交）。
- 报告不展示 R 源码：报告 chunk 一律 `#| echo: false`（`code-fold: true` 只在 echo 的块上生效，会把源码折进 `<details>`）；判据是产物中 `<pre` 与 `class="sourceCode` 计数为 0——字面 grep 会假阴性（标识符被 token 包进 span、`<-` 被转义成 `&lt;-`）。七周产物均按此判据验证为 0。
- 内部笔记（自检表、判定行、变更记录）只写渲染日志（`cat(..., file = stderr())`）与源码注释，不得进 HTML；改完 grep 产物确认。
- 改 `assets/tt_theme.R` 属共享依赖变更：必须广播各周作者并重渲染受影响周（含 `TT_TYPE` 字号阶梯与重量预算常量）。

## 文档地图
- 用户入口 → [README.md](README.md)
- 设计与契约 → [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- 每周流程与 qmd 模板 → [weeks/README.md](weeks/README.md) · 周目录规则 → [weeks/AGENTS.md](weeks/AGENTS.md)
- 取数与站点脚本 → [code/README.md](code/README.md) · 约束 → [code/AGENTS.md](code/AGENTS.md)
- 共享样式 → [assets/README.md](assets/README.md)
- 决策记录 → [.agents/notes/](.agents/notes/)
