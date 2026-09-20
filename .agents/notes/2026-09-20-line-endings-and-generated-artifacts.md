# 决策：行尾约定与生成物边界（2026-09-20）

已实施：硬判据收敛为「单文件内不得混用行尾」；CRLF 的生成物与既有资产不重写，只把唯一的混合行尾文件归一到 LF。

## 问题
- 仓库行尾是两分现状，不是统一：手写 `.md` / `.qmd` / `.yml` / `.R` 为 LF；`assets/styles.css`（手写但 CRLF，早于全部活动）、`index.html`（`code/update_site.R` 生成）、Quarto 产物（`output/*.html`、`code/.gitignore`）为 CRLF。
- `check-line-endings.py` 不带 `--target` 时只把「单文件混用行尾」判为不一致：修复前唯一的混合文件是 `weeks/2026-08-04/code/_quarto.yml`，已归一，现全仓 0 个。
- 危险动作在写入模式：`--target lf --write` 会一次改写全仓 23 个 CRLF 文件（HTML / CSS / .gitignore 三类 17 个，其中已提交 5 个；另 6 个是 `.quarto/_freeze` 缓存与 `debug_render.txt`，均未提交）。

## 决策
- 硬判据 = 单文件内不得混用行尾；不追求全仓统一到同一行尾。
- `weeks/2026-08-04/code/_quarto.yml` 归一到 LF（与其余六周同名文件一致），内容字节不变。
- 校验命令、当前分布与写入模式风险写进根 [AGENTS.md](../../AGENTS.md) 的「常用命令」与「活跃坑」。

## 替代方案
- 全仓归一为 LF：改写 23 个 CRLF 文件（HTML / CSS / .gitignore 三类 17 个，其中已提交 5 个），还会卷进 `.quarto/_freeze` 缓存，diff 噪音远大于收益。
- 全仓归一为 CRLF：与手写 md / qmd 的既有 LF 冲突，且在 LF 工具链下反复漂移。
- 加 `.gitattributes` 强制 `text=auto`：能把行尾挡在提交层，但本轮未引入、未实测其对生成产物 diff 的影响，且它取代不了「单文件不得混用」的体检。
- 把 `assets/styles.css` 一并归一到 LF：它确实属于「手写却 CRLF」的例外，但改写 192 行只制造与内容无关的 diff，收益为零，故记为已知例外而非修复。

## 影响
- `--ext` 集合靠人工枚举：新增手写文件类型（如 `.css`、`.txt`）不会被自动纳入，需按需补。
- 仓库无 `.gitattributes`、CI 不校验行尾：本约定靠人与会话遵守，机器兜底只有只读模式的混合检测。
