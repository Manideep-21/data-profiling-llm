safe_parse_dates <- function(x) {
  formats <- c("%Y-%m-%d", "%m/%d/%Y", "%d-%m-%Y")
  parsed <- rep(as.Date(NA), length(x))

  for (fmt in formats) {
    still_missing <- is.na(parsed) & !is.na(x)
    if (!any(still_missing)) {
      break
    }

    attempt <- suppressWarnings(as.Date(x[still_missing], format = fmt))
    parsed[still_missing] <- attempt
  }

  parsed
}

infer_column_kind <- function(column) {
  if (inherits(column, "Date")) {
    return("date")
  }

  numeric_values <- safe_numeric(column)
  non_missing_count <- sum(!is.na(column))
  numeric_ratio <- if (non_missing_count == 0) 0 else mean(!is.na(numeric_values[!is.na(column)]))

  if (is.numeric(column) || numeric_ratio >= 0.9) {
    return("numeric")
  }

  if (is.character(column) && is_date_like(column)) {
    return("date_like")
  }

  "categorical"
}

is_date_like <- function(x) {
  if (!is.character(x)) {
    return(FALSE)
  }

  parsed <- safe_parse_dates(x)
  success_rate <- mean(!is.na(parsed))
  success_rate >= 0.6
}

detect_issues <- function(data) {
  issues <- list()

  duplicate_rows <- which(duplicated(data))
  if (length(duplicate_rows) > 0) {
    issues[[length(issues) + 1]] <- list(
      issue_type = "duplicates",
      column = "dataset",
      severity = "high",
      message = sprintf("Duplicate rows found: %d", length(duplicate_rows)),
      details = list(rows = duplicate_rows)
    )
  }

  for (name in names(data)) {
    column <- data[[name]]
    non_missing <- column[!is.na(column)]
    missing_pct <- if (length(column) == 0) 0 else round(mean(is.na(column)) * 100, 2)
    column_kind <- infer_column_kind(column)

    if (missing_pct > 0) {
      issues[[length(issues) + 1]] <- list(
        issue_type = "missing_values",
        column = name,
        severity = if (missing_pct >= 20) "high" else "medium",
        message = sprintf("Column %s: Missing values %.2f%%", name, missing_pct),
        details = list(missing_pct = missing_pct, column_kind = column_kind)
      )
    }

    if (missing_pct >= CONFIG$missing_drop_threshold_pct) {
      issues[[length(issues) + 1]] <- list(
        issue_type = "high_missing_column",
        column = name,
        severity = "high",
        message = sprintf("Column %s: Missing values above drop threshold (%.2f%%)", name, missing_pct),
        details = list(missing_pct = missing_pct, threshold = CONFIG$missing_drop_threshold_pct)
      )
    }

    if (is.character(column)) {
      empty_pct <- if (length(column) == 0) 0 else round(mean(trimws(column) == "", na.rm = TRUE) * 100, 2)
      if (is.finite(empty_pct) && empty_pct > 0) {
        issues[[length(issues) + 1]] <- list(
          issue_type = "empty_strings",
          column = name,
          severity = "medium",
          message = sprintf("Column %s: Empty strings %.2f%%", name, empty_pct),
          details = list(empty_pct = empty_pct)
        )
      }
    }

    numeric_values <- safe_numeric(column)
    convertible_ratio <- if (sum(!is.na(column)) == 0) 0 else mean(!is.na(numeric_values[!is.na(column)]))

    if (column_kind == "numeric" && !is.numeric(column) && length(non_missing) > 0 && convertible_ratio < 1) {
      issues[[length(issues) + 1]] <- list(
        issue_type = "type_mismatch",
        column = name,
        severity = "high",
        message = sprintf("Column %s: Stored as text with non-numeric values present", name),
        details = list(convertible_ratio = round(convertible_ratio, 2))
      )
    }

    if (identical(column_kind, "date_like")) {
      issues[[length(issues) + 1]] <- list(
        issue_type = "type_mismatch",
        column = name,
        severity = "medium",
        message = sprintf("Column %s: Stored as string but looks like date", name),
        details = list(target_type = "Date")
      )
    }

    valid_numeric <- numeric_values[!is.na(numeric_values)]
    if (identical(column_kind, "numeric") && length(valid_numeric) >= 4) {
      q1 <- stats::quantile(valid_numeric, 0.25, na.rm = TRUE, names = FALSE)
      q3 <- stats::quantile(valid_numeric, 0.75, na.rm = TRUE, names = FALSE)
      iqr_value <- q3 - q1
      lower_bound <- q1 - 1.5 * iqr_value
      upper_bound <- q3 + 1.5 * iqr_value
      outlier_count <- sum(valid_numeric < lower_bound | valid_numeric > upper_bound, na.rm = TRUE)

      if (outlier_count > 0) {
        issues[[length(issues) + 1]] <- list(
          issue_type = "outliers",
          column = name,
          severity = "medium",
          message = sprintf("Column %s: Outliers detected (%d values)", name, outlier_count),
          details = list(outlier_count = outlier_count, lower_bound = lower_bound, upper_bound = upper_bound)
        )
      }

      if (mean(valid_numeric, na.rm = TRUE) > stats::median(valid_numeric, na.rm = TRUE) * 1.5) {
        issues[[length(issues) + 1]] <- list(
          issue_type = "skewed_distribution",
          column = name,
          severity = "low",
          message = sprintf("Column %s: Right-skewed distribution detected", name),
          details = list()
        )
      }
    }

    if (name %in% c("Age", "Score")) {
      invalid_rows <- which(!is.na(numeric_values) & ((name == "Age" & (numeric_values < 0 | numeric_values > 120)) |
        (name == "Score" & (numeric_values < 0 | numeric_values > 100))))
      if (length(invalid_rows) > 0) {
        issues[[length(issues) + 1]] <- list(
          issue_type = "invalid_range",
          column = name,
          severity = "high",
          message = sprintf("Column %s: Invalid range values found", name),
          details = list(rows = invalid_rows)
        )
      }
    }

    if (length(non_missing) > 0 && identical(column_kind, "categorical")) {
      unique_ratio <- length(unique(non_missing)) / length(non_missing)
      if (unique_ratio > 0.8 && length(unique(non_missing)) >= 10) {
        issues[[length(issues) + 1]] <- list(
          issue_type = "high_cardinality",
          column = name,
          severity = "low",
          message = sprintf("Column %s: High cardinality detected", name),
          details = list(unique_ratio = round(unique_ratio, 2))
        )
      }
    }
  }

  correlation_analysis <- compute_correlation_analysis(data)
  if (nrow(correlation_analysis$high_pairs) > 0) {
    for (row_index in seq_len(nrow(correlation_analysis$high_pairs))) {
      pair <- correlation_analysis$high_pairs[row_index, , drop = FALSE]
      issues[[length(issues) + 1]] <- list(
        issue_type = "high_correlation",
        column = pair$feature_b[[1]],
        severity = "medium",
        message = sprintf(
          "Columns %s and %s are highly correlated (%.2f)",
          pair$feature_a[[1]],
          pair$feature_b[[1]],
          pair$correlation[[1]]
        ),
        details = list(
          feature_a = pair$feature_a[[1]],
          feature_b = pair$feature_b[[1]],
          correlation = pair$correlation[[1]]
        )
      )
    }
  }

  issues
}
