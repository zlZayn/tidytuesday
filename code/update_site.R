# ==============================================================================
# update_site.R - 生成 GitHub Pages 入口页 index.html
# ------------------------------------------------------------------------------
# 用法: Rscript code/update_site.R
#
# 行为:
#   1. 扫描 weeks/<date>/output/ 下所有 02_exploratory_visualization.html
#   2. 按日期排序，最新周作为默认展示（iframe 嵌入）
#   3. 生成 index.html（含历史周链接列表）到项目根目录
# ------------------------------------------------------------------------------
# 依赖: 无第三方包，纯 base R
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 扫描各周的可视化产物
# ------------------------------------------------------------------------------
week_dirs <- list.dirs("weeks", recursive = FALSE, full.names = TRUE)
weeks <- character(0)
for (d in week_dirs) {
  viz <- file.path(d, "output", "02_exploratory_visualization.html")
  if (file.exists(viz)) {
    weeks <- c(weeks, d)
  }
}
weeks <- sort(weeks, decreasing = TRUE)  # 最新在前

if (length(weeks) == 0) {
  stop("未找到任何周的可视化产物（weeks/<date>/output/02_exploratory_visualization.html）")
}

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
rel_viz <- function(week_dir) {
  file.path(basename("."), week_dir, "output", "02_exploratory_visualization.html")
}

links <- vapply(weeks, function(d) {
  viz <- file.path(d, "output", "02_exploratory_visualization.html")
  title <- get_title(viz)
  date_str <- basename(d)
  sprintf(
    '<li><a href="%s" onclick="loadViz(this)">%s</a> <span class="date">%s</span></li>',
    rel_viz(d), title, date_str
  )
}, character(1))

latest_viz <- rel_viz(weeks[1])
latest_title <- get_title(file.path(weeks[1], "output", "02_exploratory_visualization.html"))
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
  '    width: 240px; background: #fff; border-right: 1px solid #e5e5e7;',
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
  '    <h2>Weekly Visualizations</h2>',
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
  '<footer>自动生成于 ', format(Sys.Date(), "%Y-%m-%d"), ' · 由 update_site.R 维护</footer>',
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
cat("    最新周:", latest_date, "-", latest_title, "\n")
cat("    历史周:", length(weeks) - 1, "个\n")
