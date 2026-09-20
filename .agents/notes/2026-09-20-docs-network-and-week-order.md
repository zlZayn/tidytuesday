# 决策：文档网络落地与缺周推进顺序（2026-09-20）

已实施：根 `AGENTS.md`、`docs/ARCHITECTURE.md`、`.agents/notes/` 与 `weeks` / `code` / `assets` 子双件均落地。

## 问题
- 项目此前只有根 README 与 weeks/README，没有自动注入的规则层：Agent 进入目录时看不到该遵守什么。
- 六个周（2026-08-11 ~ 2026-09-15）已取数、已放 `01_data_check.qmd`，但没有产物，也未定先做哪一步。（现状：六周 01 与 02 均已产出，见 [AGENTS.md](../../AGENTS.md) 验证快照。）

## 决策
- 文档分三层：根 README 面向访客，根 AGENTS.md 作仪表盘与文档地图，`docs/ARCHITECTURE.md` 写设计与契约；可维护目录补 `AGENTS.md` + `README.md` 双件。
- 缺周先跑第一个 qmd（`01_data_check.qmd` 参数化模板，只改 `params$week`），可视化 qmd 留待下一轮。
- 链接与换行校验交给 maintenance-flow 的 `check-links.py`、`check-line-endings.py` 兜底，规则文字不重复脚本职责。

## 替代方案
- 规则写进根 README：README 不自动注入，进目录时看不到；且会把门面撑成维护手册。
- 每周手写一份数据检查 qmd（沿用 2026-08-04 的做法）：六周等于复制六份相同代码，修一处要改六处。
- 六周同时铺开数据检查 + 可视化：可视化需逐周读数据故事，一次性铺开无法逐周核对结论。
- 只建根 AGENTS.md、不给子目录双件：子目录特有约束（周目录命名、脚本只跑 base R）无处安放，只能堆回根文件。

## 影响
- 根 AGENTS.md 每次会话自动注入：只留仪表盘含量，细节下沉到子 README。
- 参数化 `01_data_check.qmd` 与 2026-08-04 手写版并存：历史周不迁移。
- 缺周在站点上仍不可见，直到渲染出任一产物并提交（现规则为 02 优先、回退 01；渲染已完成，未提交前 CI 不会重扫目录）。
