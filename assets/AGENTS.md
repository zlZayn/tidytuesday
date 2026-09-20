# assets/ — 规则层

继承根规则，见 [../AGENTS.md](../AGENTS.md)。

assets/ 特有约束：
- 这里的样式与字体被所有周共用：改完至少重渲染一周确认无回归。
- 只放跨周复用资源；某周专用图片放 `weeks/<date>/code/images/`。
- 文件名变更属于契约变更：必须同步各周 qmd 的 `css:` 路径与 [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)。
