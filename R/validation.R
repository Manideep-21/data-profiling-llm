validate_data <- function(data) {
  issues <- detect_issues(data)

  list(
    valid = length(issues) == 0,
    issue_count = length(issues),
    issues = issues
  )
}
