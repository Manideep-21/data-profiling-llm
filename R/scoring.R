compute_score <- function(data) {
  issues <- detect_issues(data)
  penalties <- c(
    missing_values = 3,
    duplicates = 10,
    outliers = 4,
    type_mismatch = 8,
    invalid_range = 8,
    empty_strings = 2,
    skewed_distribution = 1,
    high_cardinality = 1
  )

  total_penalty <- 0
  for (issue in issues) {
    total_penalty <- total_penalty + penalties[[issue$issue_type]]
  }

  max(0, 100 - total_penalty)
}
