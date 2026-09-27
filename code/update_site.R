# ==============================================================================
# update_site.R - 生成站点入口页 index.html
# ------------------------------------------------------------------------------
# 用法: Rscript code/update_site.R
#
# 行为:
#   1. 扫描 weeks/<date>/output/：优先取 02_exploratory_visualization.html，
#      缺失时回退 01_data_check.html（保证每一周都进周列表）
#   2. 按目录名排序（新 -> 旧），最新周为默认展开项
#   3. 读取 assets/site/ 下的模板与静态资源，替换占位符，写出根 index.html
#
# 入口页只是「tab 壳」：首屏不含任何 iframe，也不产生任何报告请求；
# 点击某个周次时，浏览器才创建该周的 iframe 并设 src，只下载那一周。
# ------------------------------------------------------------------------------
# ⚠ 硬编码约定（本脚本与每周 qmd 模板互相配合，改动任一侧都会破坏部署）:
#   1. 可视化产物固定名: weeks/<date>/output/02_exploratory_visualization.html
#      - 来自 qmd 模板: 每周渲染 02_exploratory_visualization.qmd 得到同名 html
#   2. 回退产物固定名: weeks/<date>/output/01_data_check.html
#      - 该周没有 02 时以它进列表，条目带「数据检查」标记
#   3. 周目录命名: weeks/<YYYY-MM-DD>/（字符串排序即时间排序）
#      - 最新周 = 目录名最大的那一个
#   4. 入口页模板与静态资源固定名: assets/site/index.template.html
#                                  assets/site/hub.css
#                                  assets/site/hub.js
#      - 模板占位符: @@HUB_CSS@@ / @@HUB_DATA@@ / @@HUB_JS@@ / @@REPO_URL@@
#      - 用 @@NAME@@ 而不是 {{NAME}}，避免与 CSS/JS 的大量花括号混淆
#   5. 每周流程: 渲染出 HTML 后 push 即可，下次部署自动重扫目录，无需改脚本
#   若改模板文件名、占位符或目录结构，必须同步改这里。
# ------------------------------------------------------------------------------
# 依赖: 无第三方包，纯 base R
# ==============================================================================

VIZ_FILE <- "02_exploratory_visualization.html"
CHECK_FILE <- "01_data_check.html"

TEMPLATE <- "assets/site/index.template.html"
HUB_CSS <- "assets/site/hub.css"
HUB_JS <- "assets/site/hub.js"

REPO_URL <- "https://github.com/zlZayn/tidytuesday"
REPO_BRANCH <- "main"

# ------------------------------------------------------------------------------
# 0. 工具函数
# ------------------------------------------------------------------------------

# 把任意字符串转成 JSON 字符串字面量（含引号）
# 转义顺序：反斜杠必须最先处理，否则会二次转义
json_str <- function(x) {
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub("\"", "\\\"", x, fixed = TRUE)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  x <- gsub("\r", "\\r", x, fixed = TRUE)
  x <- gsub("\t", "\\t", x, fixed = TRUE)
  # 防止标题里的 </script> 提前闭合承载 JSON 的 script 标签
  x <- gsub("</", "<\\/", x, fixed = TRUE)
  paste0("\"", x, "\"")
}

read_text <- function(path, what) {
  if (!file.exists(path)) {
    stop(sprintf("缺少 %s：%s（模板与静态资源是入口页生成的输入）", what, path))
  }
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

# 从 html 的 <title> 取标题，取不到则退回目录名
get_title <- function(html_path) {
  raw <- readLines(html_path, warn = FALSE)
  html_txt <- paste(raw, collapse = "\n")
  m <- regexpr("<title>[^<]*</title>", html_txt)
  if (m[1] > 0) {
    t <- regmatches(html_txt, m)
    trimws(gsub("</?title>", "", t))
  } else {
    basename(dirname(dirname(html_path)))
  }
}

# ------------------------------------------------------------------------------
# 1. 扫描各周产物（02 优先，回退 01）
# ------------------------------------------------------------------------------
week_dirs <- list.dirs("weeks", recursive = FALSE, full.names = TRUE)
weeks <- character(0)
files <- character(0)
for (d in week_dirs) {
  if (file.exists(file.path(d, "output", VIZ_FILE))) {
    weeks <- c(weeks, d)
    files <- c(files, VIZ_FILE)
  } else if (file.exists(file.path(d, "output", CHECK_FILE))) {
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
# 2. 组装每周一条数据（date / title / kind / src / repo）
# ------------------------------------------------------------------------------
dates <- basename(weeks)
titles <- vapply(seq_along(weeks), function(i) {
  get_title(file.path(weeks[i], "output", files[i]))
}, character(1))
kinds <- ifelse(files == VIZ_FILE, "", "数据检查")

# 路径一律用正斜杠：这是 URL，不是文件系统路径
srcs <- sprintf("./weeks/%s/output/%s", dates, files)
repos <- sprintf("%s/tree/%s/weeks/%s", REPO_URL, REPO_BRANCH, dates)

week_json <- vapply(seq_along(dates), function(i) {
  sprintf(
    '    { "date": %s, "title": %s, "kind": %s, "src": %s, "repo": %s }',
    json_str(dates[i]), json_str(titles[i]), json_str(kinds[i]),
    json_str(srcs[i]), json_str(repos[i])
  )
}, character(1))

hub_data <- paste0(
  "{\n",
  '  "generated": ', json_str(format(Sys.Date(), "%Y-%m-%d")), ",\n",
  '  "repo": ', json_str(REPO_URL), ",\n",
  '  "weeks": [\n', paste(week_json, collapse = ",\n"), "\n  ]\n",
  "}"
)

# ------------------------------------------------------------------------------
# 3. 读模板与静态资源，替换占位符
# ------------------------------------------------------------------------------
template <- read_text(TEMPLATE, "入口页模板")
hub_css <- read_text(HUB_CSS, "入口页样式")
hub_js <- read_text(HUB_JS, "入口页脚本")

# 固定字符串替换（fixed = TRUE），避免 CSS/JS 里的正则元字符被解释
fill <- function(text, key, value) gsub(key, value, text, fixed = TRUE)

# 先校验模板，且必须在注入之前查：
#   1) 出现的占位符必须都在已知集合内（防止拼错名字，静默漏填）
#   2) 每个占位符必须恰好出现一次
#      —— 替换是全局的（gsub 替换所有出现）。若占位符在模板里出现两次
#      （例如写进了解释性注释），整份 CSS/JS/JSON 会被塞两遍，产出体积翻倍且
#      结构错乱，而页面仍能打开，属于最难发现的静默故障。
#   3) 注入内容（hub.css / hub.js）的注释里也会出现占位符字样，所以这一检查
#      必须针对注入前的模板，注入之后再扫就没有意义了。
known <- c("@@HUB_CSS@@", "@@HUB_DATA@@", "@@HUB_JS@@", "@@REPO_URL@@")
found <- regmatches(template, gregexpr("@@[A-Z_]+@@", template))[[1]]

unknown <- setdiff(unique(found), known)
if (length(unknown) > 0) {
  stop(sprintf("模板里有未知占位符: %s", paste(unknown, collapse = ", ")))
}

counts <- table(found)
dup <- names(counts)[counts > 1]
if (length(dup) > 0) {
  stop(sprintf("模板里占位符重复出现（内容会被注入多次）: %s",
               paste(sprintf("%s x%d", dup, counts[dup]), collapse = ", ")))
}

missing <- setdiff(known, unique(found))
if (length(missing) > 0) {
  stop(sprintf("模板缺少占位符: %s", paste(missing, collapse = ", ")))
}

out <- template
out <- fill(out, "@@HUB_CSS@@", hub_css)
out <- fill(out, "@@HUB_DATA@@", hub_data)
out <- fill(out, "@@HUB_JS@@", hub_js)
out <- fill(out, "@@REPO_URL@@", REPO_URL)

# 替换后不应再残留任何占位符
if (length(regmatches(out, gregexpr("@@[A-Z_]+@@", out))[[1]]) > 0) {
  stop("替换后仍残留占位符，模板或替换键不一致")
}

# ------------------------------------------------------------------------------
# 4. 写出 index.html
# ------------------------------------------------------------------------------
writeLines(strsplit(out, "\n", fixed = TRUE)[[1]], "index.html", useBytes = TRUE)

# ------------------------------------------------------------------------------
# 5. 渲染日志（只进 stdout，不进 HTML）
# ------------------------------------------------------------------------------
cat(sprintf("==> index.html 已生成（%.1f KB）\n", file.size("index.html") / 1024))
cat(sprintf("    收录周数: %d（可视化 %d · 数据检查回退 %d）\n",
            length(weeks), sum(files == VIZ_FILE), sum(files == CHECK_FILE)))
cat(sprintf("    最新周: %s - %s\n", dates[1], titles[1]))
cat(sprintf("    历史周: %d 个\n", length(weeks) - 1))
cat("    加载策略: 首屏仅 tab 壳，点击周次才加载该周报告\n")
cat(sprintf("    模板: %s\n", TEMPLATE))
