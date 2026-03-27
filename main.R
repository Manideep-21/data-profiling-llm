source("requirements.R")
source("config.R")
source("R/load_data.R")
source("R/profiling.R")
source("R/detect_issues.R")
source("R/feature_reduction.R")
source("R/llm_interface.R")
source("R/recommendation.R")
source("R/user_input.R")
source("R/apply_fixes.R")
source("R/validation.R")
source("R/scoring.R")
source("R/report.R")
source("R/visualization.R")

dir.create(CONFIG$output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(CONFIG$report_dir, recursive = TRUE, showWarnings = FALSE)

cat(sprintf("LLM provider mode: %s\n", CONFIG$llm_provider))
cat(sprintf("Interactive approval: %s\n", ifelse(CONFIG$interactive_mode && !CONFIG$auto_approve_recommended, "enabled", "disabled")))

data <- load_data()
profile_before <- profile_data(data)
issues <- detect_issues(data)
correlation_before <- compute_correlation_analysis(data)
save_correlation_heatmap(correlation_before$matrix)
suggestions <- get_llm_suggestions(profile_before, issues)
selected_fixes <- user_select(suggestions)
cleaned_data <- apply_fixes(data, selected_fixes, issues)
profile_after <- profile_data(cleaned_data)
validation_result <- validate_data(cleaned_data)
score_before <- compute_score(data)
score_after <- compute_score(cleaned_data)
visualizations <- generate_visualizations(data, issues, score_before, score_after)

generate_report(
  profile_before = profile_before,
  profile_after = profile_after,
  issues = issues,
  correlation_analysis = correlation_before,
  suggestions = suggestions,
  selected_fixes = selected_fixes,
  score_before = score_before,
  score_after = score_after,
  validation_result = validation_result,
  visualizations = visualizations
)

utils::write.csv(cleaned_data, CONFIG$cleaned_data_path, row.names = FALSE)

cat("Pipeline completed successfully.\n")
cat(sprintf("Cleaned data saved to: %s\n", CONFIG$cleaned_data_path))
cat(sprintf("Report saved"))