get_config <- function() {
  list(
    data_path = "data/sample_dataset.csv",
    output_dir = "output",
    report_dir = "reports",
    cleaned_data_path = "output/cleaned_dataset.csv",
    report_path = "reports/final_report.md",
    llm_mode = Sys.getenv("DQ_LLM_MODE", unset = "mock"),
    llm_api_key = Sys.getenv("OPENAI_API_KEY", unset = ""),
    auto_approve_recommended = TRUE,
    interactive_mode = interactive()
  )
}

CONFIG <- get_config()
