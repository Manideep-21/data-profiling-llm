format_issue_for_prompt <- function(issue) {
  sprintf("[%s] %s", issue$severity, issue$message)
}

build_fix_options <- function(issue) {
  switch(
    issue$issue_type,
    missing_values = {
      kind <- issue$details$column_kind %||% "numeric"
      if (kind == "numeric") {
        list(
          list(action = "fill_missing_median", label = "Fill with median"),
          list(action = "fill_missing_mean", label = "Fill with mean"),
          list(action = "remove_rows_missing", label = "Remove affected rows")
        )
      } else {
        list(
          list(action = "fill_missing_mode", label = "Fill with mode"),
          list(action = "remove_rows_missing", label = "Remove affected rows")
        )
      }
    },
    duplicates = {
      list(
        list(action = "remove_duplicates", label = "Remove duplicate rows")
      )
    },
    type_mismatch = {
      if (!is.null(issue$details$target_type) && identical(issue$details$target_type, "Date")) {
        list(
          list(action = "convert_to_date", label = "Convert to Date"),
          list(action = "remove_rows_invalid_type", label = "Remove invalid rows")
        )
      } else {
        list(
          list(action = "convert_to_numeric", label = "Convert to numeric"),
          list(action = "remove_rows_invalid_type", label = "Remove invalid rows")
        )
      }
    },
    outliers = {
      list(
        list(action = "cap_outliers", label = "Cap outliers to IQR bounds"),
        list(action = "remove_outliers", label = "Remove outlier rows")
      )
    },
    invalid_range = {
      list(
        list(action = "replace_invalid_with_na", label = "Replace invalid values with NA"),
        list(action = "remove_rows_invalid_range", label = "Remove invalid rows")
      )
    },
    empty_strings = {
      list(
        list(action = "empty_strings_to_na", label = "Convert empty strings to NA")
      )
    },
    skewed_distribution = {
      list(
        list(action = "log_transform", label = "Apply log transform"),
        list(action = "no_change", label = "Keep as-is")
      )
    },
    high_cardinality = {
      list(
        list(action = "group_rare_categories", label = "Group rare categories"),
        list(action = "no_change", label = "Keep as-is")
      )
    },
    list(list(action = "no_change", label = "No change"))
  )
}

recommend_best_fix <- function(issue, options) {
  preferred <- switch(
    issue$issue_type,
    missing_values = if ((issue$details$column_kind %||% "numeric") == "numeric") "fill_missing_median" else "fill_missing_mode",
    duplicates = "remove_duplicates",
    type_mismatch = if (!is.null(issue$details$target_type) && identical(issue$details$target_type, "Date")) "convert_to_date" else "convert_to_numeric",
    outliers = "cap_outliers",
    invalid_range = "replace_invalid_with_na",
    empty_strings = "empty_strings_to_na",
    skewed_distribution = "log_transform",
    high_cardinality = "group_rare_categories",
    "no_change"
  )

  match_index <- which(vapply(options, function(option) identical(option$action, preferred), logical(1)))
  if (length(match_index) == 0) {
    return(options[[1]])
  }

  options[[match_index[1]]]
}

recommendation_reason <- function(issue, recommendation) {
  switch(
    recommendation$action,
    fill_missing_median = "Median is robust to outliers and usually safer than the mean.",
    fill_missing_mean = "Mean preserves the overall average when the distribution is stable.",
    fill_missing_mode = "Mode imputation is a practical default for categorical columns.",
    remove_duplicates = "Duplicate rows distort counts and should usually be removed.",
    convert_to_numeric = "Converting the column preserves usable numeric values for analysis.",
    convert_to_date = "Date conversion enables validation and time-based analysis.",
    cap_outliers = "Capping keeps rows while reducing the distortion from extreme values.",
    replace_invalid_with_na = "Replacing impossible values with NA avoids introducing false data.",
    empty_strings_to_na = "Empty strings should be standardized so missingness can be handled consistently.",
    log_transform = "Log transform reduces skewness while preserving ordering.",
    group_rare_categories = "Grouping rare categories reduces fragmentation in categorical analysis.",
    "This is the most practical default fix for the detected issue."
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

get_mock_llm_suggestions <- function(profile, issues) {
  suggestions <- lapply(seq_along(issues), function(index) {
    issue <- issues[[index]]
    options <- build_fix_options(issue)
    recommendation <- recommend_best_fix(issue, options)

    list(
      issue_id = index,
      issue = issue,
      explanation = sprintf("The issue '%s' can reduce data quality or model reliability.", issue$message),
      options = options,
      recommended = recommendation,
      reason = recommendation_reason(issue, recommendation)
    )
  })

  list(
    prompt_summary = list(
      dataset_rows = profile$dataset$rows,
      dataset_columns = profile$dataset$columns,
      issue_count = length(issues),
      issues = vapply(issues, format_issue_for_prompt, character(1))
    ),
    suggestions = suggestions
  )
}

get_llm_suggestions <- function(profile, issues) {
  mode <- tolower(CONFIG$llm_mode)

  if (length(issues) == 0) {
    return(list(prompt_summary = list(), suggestions = list()))
  }

  if (identical(mode, "mock") || identical(CONFIG$llm_api_key, "")) {
    return(get_mock_llm_suggestions(profile, issues))
  }

  warning("Live LLM mode is configured but not implemented in this offline-safe template. Falling back to mock suggestions.")
  get_mock_llm_suggestions(profile, issues)
}
