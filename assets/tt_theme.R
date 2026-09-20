# assets/tt_theme.R —— 可视化工艺底线（不含配色）
#
# 定位：这里只沉淀"六周共同遵守的工艺"，不提供唯一配色。
#       每周的调色板在本周 02 qmd 顶部自行声明（六周互不相同）。
# 用法：在周 qmd 的 setup chunk 里 source() 本文件，然后 tt_base(...) + 本周自定色彩。
#
# 底线清单（新增/修改图表时必须满足）：
#   - 图内文字一律英文；正文与表格注释可中文。
#   - 标题说洞察、副标题说口径、脚注说数据来源与样本量；三者一律左对齐（plot 位置而非 panel 位置）。
#   - 网格：仅主网格，细线；不使用次网格。
#   - 导出：显式 width / height / dpi / bg（bg 与本周底色一致），不依赖默认值。
#   - 禁用：饼图、双 Y 轴、彩虹色板、重叠标签、图例级别 > 6（改分面或筛选）。
#   - 同一类别跨图同色；同一类别跨图同一标签（含 n）。
#   - 正文引用的每个数字必须来自图上同一份聚合（优先用 inline R 引用变量，不手打）。
#     图只画子集时，必须写清「原始 N -> 入图 n」的筛选链与差额（用 tt_flow() 生成这一行）。
#   - 内部笔记不得进入渲染产物：自检 / 审计表 / 判定行 / 口径校验表 / 变更与缺陷记录 /
#     面向维护者的过程说明，一律用 "#| include: false"（或 output: false）只留在渲染日志，
#     或写进 R 注释 / HTML 注释 <!-- -->；HTML 里不得出现「排版自检 / 越阶 / 上限 / tt_audit /
#     TT_TYPE / 写死字号」这类维护者字样。读者需要的口径说明（样本口径、剔除原因、数据异常）保留在正文。
#   - 隐藏自检用 "#| include: false"（新开块也可）；若整段 R 源码出现在页面上，先查 fence 是否成对、
#     "#|" 是否落在块内 —— 已用最小用例验证新开块可正常工作。
#   - 隐藏自检后必须 grep 产物自证：七类维护者字样与 R 源码标记（#| / library( / read_csv( / stopifnot( /
#     ggplot( / tt_base( / PAL$ / source( / |>）都不得出现在 HTML 里；判据是 grep 产物本身。
#   - 排版纪律（字号 / 家族 / 重叠 / 层次）：一律走 TT_TYPE 阶梯与 tt_base()，别自己发明字号。
#     允许给阶梯起别名（如 TY <- TT_TYPE）以减少打字，但别名必须直接指向 TT_TYPE，不得另立字号表。
#     交图前必须按「原始尺度 + 缩略图（长边 ≈ 600px）」两档各看一遍：
#     缩略图是查重叠与层次崩塌最快的手段；缩略图下标题读不清或能看出压盖 = 未通过。
# 字体事实：本机 Archivo / PingFang SC 未安装，故默认落到 Segoe UI；等宽用 Consolas。

TT_FONT <- "Segoe UI"
TT_MONO <- "Consolas"

# ---- 排版纪律常量（六周共用；图内文案的每个字号都必须取自 TT_TYPE）----
# 阶梯单调递减且相邻可辨：title 16 > subtitle 13 > axis_title 11 > axis_text 9.5 > annot 8.5 > caption 7.5
TT_TYPE <- c(title = 16, subtitle = 13, axis_title = 11, axis_text = 9.5, annot = 8.5, caption = 7.5)
TT_TYPE_MAX   <- 6L                                  # 全图字号种类上限
TT_FAMILY_MAX <- 2L                                  # 全图字体家族上限
# 家族配对：下面是"推荐默认"，**不是白名单**。判据 = 家族数 <= TT_FAMILY_MAX 且按角色分工
# （标题/副标题/脚注一族 + 轴/图例/图内数字一族）；各周可按视觉身份换用本机已装字体，
# 但不得混入第三套。本机已装可选：Georgia / Times New Roman / Cambria / Constantia /
# Book Antiqua / Palatino Linotype / Segoe UI / Consolas（Archivo、PingFang SC 未装）。
TT_FAMILY <- c(text = TT_FONT, data = TT_MONO)
TT_CAPTION_WIDTH <- 118                              # 脚注折行宽度（超过会被画布右缘裁掉）

# 导出参数底线（周 qmd 可覆盖，但必须显式写）
TT_EXPORT <- list(width = 9, height = 5.4, dpi = 240)

# ---- 页面重量预算（工程约束，六周共同遵守）----
# 单图内嵌 PNG <= 2 MB、单页自包含 HTML <= 6 MB。
# 达标手段优先级：① 先降大画幅图的 fig-dpi（逐块写 "#| dpi: 200"，下限 TT_DPI_FLOOR 160）
#                 ② 再减画布尺寸 / 分层数量
#                 ③ 不得靠继续降清晰度硬压（低于 160 dpi 视为不达标）
# 自检：渲染后在 R 里跑 tt_weigh("../output/02_exploratory_visualization.html")
TT_PNG_MAX_MB  <- 2
TT_HTML_MAX_MB <- 6
TT_DPI_FLOOR   <- 160

# 重量自检：读渲染好的 HTML，报总重与每张内嵌 PNG 的 MB（按 base64 长度换算），降序返回。
tt_weigh <- function(html, quiet = FALSE) {
  if (!file.exists(html)) stop("找不到 HTML：", html)
  txt <- paste(readLines(html, warn = FALSE), collapse = "")
  b64 <- regmatches(txt, gregexpr("(?<=data:image/png;base64,)[A-Za-z0-9+/=]+", txt, perl = TRUE))[[1]]
  mb  <- if (length(b64)) ceiling(nchar(b64) * 3 / 4) / 1024^2 else numeric(0)
  ord <- order(-mb)
  res <- data.frame(png = seq_along(mb)[ord], mb = round(mb[ord], 3))
  html_mb <- file.info(html)$size / 1024^2
  attr(res, "html_mb") <- html_mb
  if (!quiet) {
    cat(sprintf("HTML %.2f MB (预算 %d) | 最大单图 %.2f MB (预算 %d) | 图数 %d\n",
                html_mb, TT_HTML_MAX_MB,
                if (length(mb)) max(mb) else 0, TT_PNG_MAX_MB, length(mb)))
    if (html_mb > TT_HTML_MAX_MB) cat("!! HTML 超预算\n")
    if (length(mb) && max(mb) > TT_PNG_MAX_MB) cat("!! 单图超预算\n")
  }
  res
}

# 通用主题工厂：只吃本周自己的颜色，不含任何固定色值；字号一律来自 TT_TYPE。
# scale：整体缩放阶梯（默认 1）。历史写法 tt_base(size = 13) 等价于 scale = 13/12，仍可用。
tt_base <- function(bg = "#FFFFFF", ink = "#111111", body = "#4A4A4A",
                    grid = "#E9E9E9", family = TT_FONT, size = NULL, scale = 1) {
  if (!is.null(size)) scale <- as.numeric(size) / 12
  ty <- TT_TYPE * scale
  ggplot2::theme_minimal(base_size = ty[["axis_title"]], base_family = family) +
    ggplot2::theme(
      plot.background       = ggplot2::element_rect(fill = bg, colour = NA),
      panel.background      = ggplot2::element_rect(fill = bg, colour = NA),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      plot.title    = ggplot2::element_text(colour = ink, face = "bold", size = ty[["title"]],
                                            hjust = 0, margin = ggplot2::margin(b = 4)),
      plot.subtitle = ggplot2::element_text(colour = body, size = ty[["subtitle"]], hjust = 0,
                                            margin = ggplot2::margin(b = 10)),
      plot.caption  = ggplot2::element_text(colour = body, size = ty[["caption"]], hjust = 0,
                                            margin = ggplot2::margin(t = 10)),
      text          = ggplot2::element_text(colour = body, size = ty[["axis_text"]]),
      axis.title    = ggplot2::element_text(colour = body, size = ty[["axis_title"]]),
      axis.text     = ggplot2::element_text(colour = body, size = ty[["axis_text"]]),
      legend.position      = "top",
      legend.justification = "left",
      legend.title         = ggplot2::element_blank(),
      legend.text          = ggplot2::element_text(size = ty[["annot"]]),
      strip.text           = ggplot2::element_text(colour = ink, face = "bold", size = ty[["axis_title"]]),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = grid, linewidth = 0.35),
      plot.margin      = ggplot2::margin(16, 18, 12, 16)
    )
}

# 排版自检：列出这张图显式设定的字体元素，标出是否落在 TT_TYPE 阶梯内。
# 用法：tt_audit(p)；通过判据 = all(d$in_ladder) 且 字号种类 <= TT_TYPE_MAX 且 家族数 <= TT_FAMILY_MAX。
# 注意：审计表与判定行属内部笔记，chunk 必须配 include: false，只让硬闸进渲染日志。示例：
#   {r, label: typography-audit, include: false}
#   aud <- tt_audit(p1)
#   stopifnot(all(aud$in_ladder), length(unique(stats::na.omit(aud$size))) <= TT_TYPE_MAX)
tt_audit <- function(p, allowed = TT_TYPE, tol = 0.05) {
  th <- p$theme
  rows <- list()
  for (e in names(th)) {
    x <- th[[e]]
    if (inherits(x, "element_text")) {
      # rel() 是相对字号（继承而来），不是绝对值：按 NA 处理，只审计写死的绝对字号
      sz <- x$size
      if (is.null(sz) || inherits(sz, "rel")) sz <- NA_real_ else sz <- as.numeric(sz)
      rows[[length(rows) + 1L]] <- data.frame(
        element = e,
        size    = sz,
        family  = if (is.null(x$family)) NA_character_ else as.character(x$family),
        stringsAsFactors = FALSE)
    }
  }
  if (!length(rows)) return(data.frame(element = character(), size = numeric(), family = character(),
                                       in_ladder = logical()))
  d <- do.call(rbind, rows)
  d$in_ladder <- is.na(d$size) | vapply(d$size, function(s) any(abs(s - allowed) < tol), TRUE)
  d[order(d$element), ]
}

# 口径链：把「原始行数 -> 入图行数」与差额原因压成一行，供正文与图注共用
tt_flow <- function(raw, kept, ...) {
  why <- unlist(list(...))
  sprintf("raw %d -> plotted %d%s", raw, kept,
          if (length(why)) paste0(" (", paste(why, collapse = "; "), ")") else "")
}

# 数据条：把口径压缩成一行等宽字（版式签名的公共零件，用不用由各周决定）
tt_strip <- function(...) paste0("[ ", paste(unlist(list(...)), collapse = " \u00b7 "), " ]")

# 脚注：统一 "Source: 文件 (n) · 口径" 形态；太长必须折行，否则会被图右边缘裁掉（已踩过）
tt_source <- function(file, n = NULL, note = NULL, width = TT_CAPTION_WIDTH) {
  parts <- paste0("Source: ", file, if (!is.null(n)) paste0(" (n = ", n, ")") else "")
  if (!is.null(note)) parts <- paste(parts, note, sep = " \u00b7 ")
  paste(strwrap(parts, width = width), collapse = "\n")
}
