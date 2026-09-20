# weeks/ — 规则层

继承根规则，见 [../AGENTS.md](../AGENTS.md)。

weeks/ 特有约束：
- 目录名固定 `YYYY-MM-DD`，一周一目录，不改名、不合并（站点按目录名排序取最新周）。
- 动手前先读 [README.md](README.md)：每周流程、qmd 模板与硬编码约定都在那里。
- `weeks/<date>/data/` 只读，清洗结果写 `weeks/<date>/output/`。
- 某周的 qmd 只读本周数据，不跨周引用；数据路径取法见根 [AGENTS.md](../AGENTS.md) 全局规则（参数化模板用 `assets/` 根标记，手写 qmd 用 `../data/`）。
- 本机未装 Archivo / PingFang SC：2026-08-04 先例的字体栈实际回落到 Segoe UI，新图不要依赖未安装字体。
- 不写「这里有什么文件 / 怎么改」，那是 [README.md](README.md) 的职责。
