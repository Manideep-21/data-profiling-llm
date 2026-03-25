compute_score <- function(data) {
  issues <- detect_issues(data)
  penalties <- c(
    missing_values = 3,
    high_missing_column = 8,
    duplicates = 10,
    outliers = 4,
    type_mismatch = 8,
    invalid_range = 8,
    empty_strings = 2,
    skewed_distribution = 1,
    high_cardinality = 1,
    high_correlation = 4
  )

  total_penalty <- 0
  for (issue in issues) {
    penalty <- penalties[[issue$issue_type]]
    if (is.null(penalty) || is.na(penalty)) {
      penalty <- 0
    }
    total_penalty <- total_penalty + penalty
  }

  max(0, 100 - total_penalty)
}
