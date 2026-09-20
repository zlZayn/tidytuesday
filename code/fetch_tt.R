# ==============================================================================
# fetch_tt.R - TidyTuesday 通用取数脚本
# ------------------------------------------------------------------------------
# 用法:
#   Rscript code/fetch_tt.R                  # 默认取今天(最近一周)
#   Rscript code/fetch_tt.R 2026-08-04       # 指定日期
#   Rscript code/fetch_tt.R 2026-08-04 --week # 用年份+周数(可选扩展)
#
# 行为:
#   下载指定周的 TidyTuesday 数据到 weeks/<date>/data/ 目录
#   并保存该周官方 readme 到 weeks/<date>/readme.md
# ------------------------------------------------------------------------------
# 路径规范: 所有路径相对于项目根目录, 不 setwd
# ==============================================================================

suppressPackageStartupMessages(library(tidytuesdayR))

# ------------------------------------------------------------------------------
# 1. 解析参数
# ------------------------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
refdate <- if (length(args) >= 1 && args[1] != "") args[1] else as.character(Sys.Date())
refdate <- as.Date(refdate)

# ------------------------------------------------------------------------------
# 2. 目标目录: weeks/<date>/
# ------------------------------------------------------------------------------
week_dir <- file.path("weeks", format(refdate, "%Y-%m-%d"))
data_dir <- file.path(week_dir, "data")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

cat("==> 拉取 TidyTuesday 数据, 日期:", format(refdate, "%Y-%m-%d"), "\n")

# ------------------------------------------------------------------------------
# 3. 下载数据
# ------------------------------------------------------------------------------
tt <- tt_load(format(refdate, "%Y-%m-%d"))

# ------------------------------------------------------------------------------
# 4. 保存每个数据集为 CSV (UTF-8, 无 BOM)
# ------------------------------------------------------------------------------
for (nm in names(tt)) {
  df <- tt[[nm]]
  out <- file.path(data_dir, paste0(nm, ".csv"))
  readr::write_csv(df, out)
  cat("   [saved]", nm, "->", out, "(", nrow(df), "x", ncol(df), ")\n")
}

# ------------------------------------------------------------------------------
# 5. 保存该周官方 readme
# ------------------------------------------------------------------------------
readme_txt <- readme(tt)
if (length(readme_txt) > 0 && !is.na(readme_txt[1])) {
  writeLines(readme_txt, file.path(week_dir, "readme.md"))
  cat("   [saved] readme ->", file.path(week_dir, "readme.md"), "\n")
}

cat("==> 完成. 数据位于:", data_dir, "\n")
