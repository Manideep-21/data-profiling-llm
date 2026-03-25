load_env_file <- function(env_path = ".env") {
  if (!file.exists(env_path)) {
    return(invisible(FALSE))
  }

  lines <- readLines(env_path, warn = FALSE)
  lines <- trimws(lines)
  lines <- lines[lines != "" & !startsWith(lines, "#")]

  for (line in lines) {
    if (!grepl("=", line, fixed = TRUE)) {
      next
    }

    key <- trimws(sub("=.*$", "", line))
    value <- trimws(sub("^[^=]*=", "", line))
    value <- gsub("^[\"']|[\"']$", "", value)

    if (nzchar(key) && identical(Sys.getenv(key, unset = ""), "")) {
      Sys.setenv(structure(value, names = key))
    }
  }

  invisible(TRUE)
}

load_env_file(".env")

get_config <- function() {
  list(
    data_path = "data/sample_dataset.csv",
    output_dir = "output",
    report_dir = "reports",
    visualization_dir = "reports/visualizations",
    cleaned_data_path = "output/cleaned_dataset.csv",
    report_path = "reports/final_report.md",
    correlation_heatmap_path = "reports/correlation_heatmap.png",
    llm_mode = Sys.getenv("DQ_LLM_MODE", unset = "gemini"),
    llm_provider = Sys.getenv("DQ_LLM_PROVIDER", unset = "gemini"),
    llm_api_key = Sys.getenv("GEMINI_API_KEY", unset = ""),
    gemini_model = Sys.getenv("GEMINI_MODEL", unset = "gemini-2.5-flash"),
    gemini_base_url = Sys.getenv("GEMINI_BASE_URL", unset = "https://generativelanguage.googleapis.com/v1beta/models"),
    missing_drop_threshold_pct = 40,
    correlation_threshold = 0.85,
    auto_approve_recommended = TRUE,
    interactive_mode = interactive()
  )
}

CONFIG <- get_config()
