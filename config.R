get_config <- function() {
  list(
    data_path = "data/sample_dataset.csv",
    output_dir = "output",
    report_dir = "reports",
    visualization_dir = "reports/visualizations",
    cleaned_data_path = "output/cleaned_dataset.csv",
    report_path = "reports/final_report.md",
    correlation_heatmap_path = "reports/correlation_heatmap.png",
    llm_mode = Sys.getenv("DQ_LLM_MODE", unset = "mock"),
    llm_api_key = Sys.getenv("OPENAI_API_KEY", unset = ""),
    missing_drop_threshold_pct = 40,
    correlation_threshold = 0.85,
    auto_approve_recommended = TRUE,
    interactive_mode = interactive()
  )
}

CONFIG <- get_config()
