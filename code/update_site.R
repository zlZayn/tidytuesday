# ==============================================================================
# update_site.R - 生成 GitHub Pages 入口页 index.html
# ------------------------------------------------------------------------------
# 用法: Rscript code/update_site.R
#
# 行为:
#   1. 扫描 weeks/<date>/output/：优先取 02_exploratory_visualization.html，
#      缺失时回退 01_data_check.html（保证每一周都进侧边栏）
#   2. 按目录名排序（新 -> 旧），最新周作为默认展示（iframe 嵌入）
#   3. 生成 index.html（含全部周链接列表）到项目根目录
# ------------------------------------------------------------------------------
# ⚠ 硬编码约定（本脚本与每周 qmd 模板互相配合，改动任一侧都会破坏部署）:
#   1. 可视化产物固定名: weeks/<date>/output/02_exploratory_visualization.html
#      - 来自 qmd 模板: 每周渲染 02_exploratory_visualization.qmd 得到同名 html
#   2. 回退产物固定名: weeks/<date>/output/01_data_check.html
#      - 该周没有 02 时以它进侧边栏，条目带「数据检查」标记
#   3. 周目录命名: weeks/<YYYY-MM-DD>/（字符串排序即时间排序）
#      - 最新周 = 目录名最大的那一个
#   4. 每周流程: 渲染出 HTML 后 push 即可，下次部署自动重扫目录，无需改动脚本
#   若改模板文件名或目录结构，必须同步改这里。
# ------------------------------------------------------------------------------
# 依赖: 无第三方包，纯 base R
# ==============================================================================

VIZ_FILE <- "02_exploratory_visualization.html"
CHECK_FILE <- "01_data_check.html"

# ------------------------------------------------------------------------------
# 1. 扫描各周产物（02 优先，回退 01）
# ------------------------------------------------------------------------------
week_dirs <- list.dirs("weeks", recursive = FALSE, full.names = TRUE)
weeks <- character(0)
files <- character(0)
for (d in week_dirs) {
  viz <- file.path(d, "output", VIZ_FILE)
  chk <- file.path(d, "output", CHECK_FILE)
  if (file.exists(viz)) {
    weeks <- c(weeks, d)
    files <- c(files, VIZ_FILE)
  } else if (file.exists(chk)) {
    weeks <- c(weeks, d)
    files <- c(files, CHECK_FILE)
  }
}

if (length(weeks) == 0) {
  stop(sprintf("未找到任何周的产物（%s 或 %s）", VIZ_FILE, CHECK_FILE))
}

ord <- order(weeks, decreasing = TRUE)  # 最新在前
weeks <- weeks[ord]
files <- files[ord]

# ------------------------------------------------------------------------------
# 2. 提取每周标题（从 html 的 <title>）
# ------------------------------------------------------------------------------
get_title <- function(html_path) {
  raw <- readLines(html_path, warn = FALSE)
  html_txt <- paste(raw, collapse = "\n")
  m <- regexpr("<title>[^<]*</title>", html_txt)
  if (m[1] > 0) {
    t <- regmatches(html_txt, m)
    gsub("</?title>", "", t)
  } else {
    basename(dirname(dirname(html_path)))
  }
}

# 相对路径：index.html 在根目录，到每周 html 的相对路径
rel_out <- function(week_dir, file_name) {
  file.path(basename("."), week_dir, "output", file_name)
}

links <- vapply(seq_along(weeks), function(i) {
  d <- weeks[i]
  path <- file.path(d, "output", files[i])
  title <- get_title(path)
  date_str <- basename(d)
  kind <- if (identical(files[i], VIZ_FILE)) "" else ' <span class="kind">数据检查</span>'
  sprintf(
    '<li><a href="%s" onclick="loadViz(this)">%s%s</a> <span class="date">%s</span></li>',
    rel_out(d, files[i]), title, kind, date_str
  )
}, character(1))

latest_viz <- rel_out(weeks[1], files[1])
latest_title <- get_title(file.path(weeks[1], "output", files[1]))
latest_date <- basename(weeks[1])

# ------------------------------------------------------------------------------
# 3. 生成 index.html（用 paste 拼接，避免 sprintf 解析 CSS 中的 %）
# ------------------------------------------------------------------------------
parts <- c(
  '<!DOCTYPE html>',
  '<html lang="zh-CN">',
  '<head>',
  '<meta charset="UTF-8">',
  '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
  '<title>TidyTuesday Visualization Hub</title>',
  '<style>',
  '  * { box-sizing: border-box; margin: 0; padding: 0; }',
  '  body {',
  '    font-family: -apple-system, "Segoe UI", "PingFang SC", "Microsoft YaHei", sans-serif;',
  '    background: #f5f5f7; color: #1d1d1f; min-height: 100vh; display: flex; flex-direction: column;',
  '  }',
  '  header {',
  '    background: #fff; border-bottom: 1px solid #e5e5e7; padding: 16px 28px;',
  '    display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px;',
  '  }',
  '  header h1 { font-size: 18px; font-weight: 700; }',
  '  header .tag { font-size: 12px; color: #86868b; }',
  '  main { flex: 1; display: flex; min-height: 0; }',
  '  aside {',
  '    width: 260px; background: #fff; border-right: 1px solid #e5e5e7;',
  '    padding: 20px 0; overflow-y: auto; flex-shrink: 0;',
  '  }',
  '  aside h2 { font-size: 12px; color: #86868b; text-transform: uppercase; letter-spacing: .05em;',
  '             padding: 0 24px 8px; }',
  '  aside ul { list-style: none; }',
  '  aside li a {',
  '    display: block; padding: 9px 24px; font-size: 13px; color: #1d1d1f;',
  '    text-decoration: none; border-left: 3px solid transparent; transition: all .15s;',
  '  }',
  '  aside li a:hover { background: #f5f5f7; }',
  '  aside li a.active { background: #f0f0f4; border-left-color: #0e8056; font-weight: 600; }',
  '  aside li .date { font-size: 11px; color: #86868b; margin-left: 6px; }',
  '  aside li .kind { font-size: 10px; color: #0e8056; border: 1px solid #b7d8c9;',
  '                   border-radius: 3px; padding: 0 4px; margin-left: 6px; vertical-align: 1px; }',
  '  .content { flex: 1; padding: 20px 28px; min-width: 0; display: flex; flex-direction: column; }',
  '  .content .meta { margin-bottom: 12px; }',
  '  .content .meta h3 { font-size: 15px; font-weight: 600; }',
  '  .content .meta .date { font-size: 12px; color: #86868b; }',
  '  iframe {',
  '    flex: 1; width: 100%; border: 1px solid #e5e5e7; border-radius: 8px;',
  '    background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,.06); min-height: 600px;',
  '  }',
  '  footer { text-align: center; padding: 14px; font-size: 12px; color: #86868b; background: #fff;',
  '           border-top: 1px solid #e5e5e7; }',
  '</style>',
  '</head>',
  '<body>',
  '<header>',
  '  <h1>TidyTuesday Visualization Hub</h1>',
  '  <span class="tag">每周 R 数据可视化 · 自动部署 GitHub Pages</span>',
  '</header>',
  '<main>',
  '  <aside>',
  '    <h2>Weekly Reports</h2>',
  '    <ul>', paste(links, collapse = "\n"), '</ul>',
  '  </aside>',
  '  <div class="content">',
  '    <div class="meta">',
  '      <h3 id="viz-title">', latest_title, '</h3>',
  '      <span class="date" id="viz-date">', latest_date, '</span>',
  '    </div>',
  '    <iframe id="viz-frame" src="', latest_viz, '" title="可视化"></iframe>',
  '  </div>',
  '</main>',
  '<footer>自动生成于 ', format(Sys.Date(), "%Y-%m-%d"), ' · 由 update_site.R 维护 · 共 ', length(weeks), ' 周</footer>',
  '<script>',
  '  function loadViz(link) {',
  '    document.getElementById("viz-frame").src = link.getAttribute("href");',
  '    document.querySelectorAll("aside a").forEach(a => a.classList.remove("active"));',
  '    link.classList.add("active");',
  '    document.getElementById("viz-title").textContent = link.childNodes[0].textContent.trim();',
  '    const dateSpan = link.querySelector(".date");',
  '    document.getElementById("viz-date").textContent = dateSpan ? dateSpan.textContent.trim() : "";',
  '  }',
  '  document.addEventListener("DOMContentLoaded", () => {',
  '    const first = document.querySelector("aside a");',
  '    if (first) first.classList.add("active");',
  '  });',
  '</script>',
  '</body>',
  '</html>'
)

writeLines(parts, "index.html", useBytes = TRUE)
cat("==> index.html 已生成\n")
cat("    收录周数:", length(weeks), "（可视化", sum(files == VIZ_FILE), "· 数据检查回退", sum(files == CHECK_FILE), "）\n")
cat("    最新周:", latest_date, "-", latest_title, "\n")
cat("    历史周:", length(weeks) - 1, "个\n")
