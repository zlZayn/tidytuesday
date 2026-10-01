#!/usr/bin/env python3
"""check_site_index.py - 校验根 index.html 与 weeks/ 目录是否同步

只检查，不生成。CI 用它代替原来的 update_site.R 重跑：
纯标准库、无第三方依赖、无网络、秒级完成。

判据：
  1. weeks/ 下每个有可用产物的周，都必须出现在 index.html 的 weeks 数组里
  2. index.html 里不得有指向已不存在产物的周条目
  3. 顺序必须是新 -> 旧
  4. 每条 src 指向的文件必须真实存在
  5. kind 必须与产物类型一致（02 -> ""，01 -> "数据检查"）

用法: python code/check_site_index.py
退出码: 0 同步 / 1 不同步（并打印该跑什么）
"""
import json
import re
import sys
from pathlib import Path

VIZ = "02_exploratory_visualization.html"
CHECK = "01_data_check.html"

ROOT = Path(__file__).resolve().parent.parent
INDEX = ROOT / "index.html"


def expected_weeks():
    """扫描 weeks/，返回 [(date, filename)]，按新 -> 旧。"""
    out = []
    for d in sorted((ROOT / "weeks").iterdir()):
        if not d.is_dir():
            continue
        if (d / "output" / VIZ).is_file():
            out.append((d.name, VIZ))
        elif (d / "output" / CHECK).is_file():
            out.append((d.name, CHECK))
    return sorted(out, key=lambda x: x[0], reverse=True)


def actual_weeks():
    html = INDEX.read_text(encoding="utf-8")
    m = re.search(
        r'<script type="application/json" id="hub-data">(.*?)</script>',
        html,
        re.S,
    )
    if not m:
        sys.exit("FATAL: index.html 里找不到 id=\"hub-data\" 的 JSON 块（index.html 可能被手改坏了）")
    try:
        data = json.loads(m.group(1))
    except json.JSONDecodeError as e:
        sys.exit(f"FATAL: hub-data 不是合法 JSON（{e}）—— index.html 被手改坏了，"
                 "重跑 Rscript code/update_site.R 覆盖它")
    if not isinstance(data.get("weeks"), list):
        sys.exit("FATAL: hub-data 里没有 weeks 数组 —— index.html 结构不对")
    return data["weeks"]


def main():
    if not INDEX.is_file():
        sys.exit("FATAL: 找不到 index.html")

    exp = expected_weeks()
    act = actual_weeks()
    errs = []

    exp_dates = [d for d, _ in exp]
    act_dates = [w.get("date") for w in act]

    for i, (date, fname) in enumerate(exp):
        if date not in act_dates:
            errs.append(f"缺少周条目: {date}（应指向 output/{fname}）")

    for w in act:
        d = w.get("date")
        if d not in exp_dates:
            errs.append(f"多余周条目: {d}（weeks/{d}/output/ 下已无可用产物）")
            continue
        fname = dict(exp)[d]
        src = w.get("src", "")
        if not src.endswith(fname):
            errs.append(f"src 与产物不符: {d} -> {src}（应为 {fname}）")
        rel = src.lstrip("./")
        if not (ROOT / rel).is_file():
            errs.append(f"src 指向的文件不存在: {d} -> {src}")
        want_kind = "" if fname == VIZ else "数据检查"
        if w.get("kind", "") != want_kind:
            errs.append(f"kind 不符: {d} -> {w.get('kind')!r}（应为 {want_kind!r}）")

    if act_dates != sorted(act_dates, reverse=True):
        errs.append(f"顺序不是新 -> 旧: {act_dates}")

    if errs:
        print("index.html 与 weeks/ 不同步：", file=sys.stderr)
        for e in errs:
            print(f"  - {e}", file=sys.stderr)
        print("", file=sys.stderr)
        print("修复：本地跑  Rscript code/update_site.R  然后提交 index.html", file=sys.stderr)
        return 1

    print(f"OK: index.html 与 weeks/ 同步（{len(exp)} 周：{exp_dates[0]} ... {exp_dates[-1]}）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
