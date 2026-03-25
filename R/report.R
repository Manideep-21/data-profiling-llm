profile_to_markdown <- function(profile, title) {
  lines <- c(
    sprintf("## %s", title),
    "",
    sprintf("- Rows: %d", profile$dataset$rows),
    sprintf("- Columns: %d", profile$dataset$columns),
    sprintf("- Duplicate rows: %d", profile$dataset$duplicate_rows),
    sprintf("- Total missing values: %d", profile$dataset$total_missing),
    ""
  )

  for (column in profile$columns) {
    lines <- c(
      lines,
      sprintf("### %s", column$name),
      sprintf("- Type: %s", column$detected_type),
      sprintf("- Missing: %d (%.2f%%)", column$missing_count, column$missing_pct),
      sprintf("- Unique values: %d", column$unique_count)
    )

    if (!is.null(column$summary$mean)) {
      lines <- c(
        lines,
        sprintf("- Mean: %s", column$summary$mean),
        sprintf("- Median: %s", column$summary$median),
        sprintf("- Min / Max: %s / %s", column$summary$min, column$summary$max),
        sprintf("- Outliers: %s", column$summary$outlier_count)
      )
    } else {
      top_values <- if (length(column$summary$top_values) > 0) {
        paste(names(column$summary$top_values), unlist(column$summary$top_values), sep = ":", collapse = ", ")
      } else {
        "None"
      }
      lines <- c(lines, sprintf("- Top values: %s", top_values))
    }

    lines <- c(lines, "")
  }

  lines
}

issues_to_markdown <- function(issues) {
  if (length(issues) == 0) {
    return(c("## Issues Detected", "", "No issues detected.", ""))
  }

  lines <- c("## Issues Detected", "")
  for (issue in issues) {
    lines <- c(lines, sprintf("- %s", issue$message))
  }
  c(lines, "")
}

suggestions_to_markdown <- function(suggestions) {
  lines <- c("## LLM Suggestions", "")

  if (length(suggestions$suggestions) == 0) {
    return(c(lines, "No suggestions generated.", ""))
  }

  for (item in suggestions$suggestions) {
    option_labels <- vapply(item$options, function(option) option$label, character(1))
    lines <- c(
      lines,
      sprintf("### Issue %d: %s", item$issue_id, item$issue$message),
      sprintf("- Explanation: %s", item$explanation),
      sprintf("- Fix options: %s", paste(option_labels, collapse = "; ")),
      sprintf("- Recommended: %s", item$recommended$label),
      sprintf("- Reason: %s", item$reason),
      ""
    )
  }

  lines
}

fixes_to_markdown <- function(selected_fixes) {
  lines <- c("## Fixes Applied", "")
  if (length(selected_fixes) == 0) {
    return(c(lines, "No fixes were applied.", ""))
  }

  for (fix in selected_fixes) {
    lines <- c(lines, sprintf("- Issue %s on `%s`: `%s`", fix$issue_id, fix$column, fix$action))
  }

  c(lines, "")
}

generate_report <- function(profile_before, profile_after, issues, suggestions, selected_fixes, score_before, score_after, validation_result, report_path = CONFIG$report_path) {
  dir.create(dirname(report_path), recursive = TRUE, showWarnings = FALSE)

  lines <- c(
    "# Data Profiling and Cleaning Report",
    "",
    sprintf("- Score before cleaning: %s", score_before),
    sprintf("- Score after cleaning: %s", score_after),
    sprintf("- Score improvement: %s", score_after - score_before),
    sprintf("- Remaining issues after validation: %s", validation_result$issue_count),
    "",
    profile_to_markdown(profile_before, "Profile Before Cleaning"),
    issues_to_markdown(issues),
    suggestions_to_markdown(suggestions),
    fixes_to_markdown(selected_fixes),
    profile_to_markdown(profile_after, "Profile After Cleaning")
  )

  writeLines(lines, con = report_path)
  invisible(report_path)
}
