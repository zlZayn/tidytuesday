# code/ — 规则层

继承根规则，见 [../AGENTS.md](../AGENTS.md)。

code/ 特有约束：
- 脚本以项目根为工作目录运行（`Rscript code/<name>.R`），脚本内部不 `setwd`。
- 只用 base R 或 [README.md](README.md) 已记录的依赖：CI 不安装第三方包。
- `update_site.R` 的文件名与目录命名约定是跨文件契约：改动必须同步 [../weeks/README.md](../weeks/README.md) 与 [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)。
