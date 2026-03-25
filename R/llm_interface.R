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
          list(action = "fill_missing_constant", label = "Fill with constant"),
          list(action = "add_missing_indicator", label = "Add missing indicator"),
          list(action = "remove_rows_missing", label = "Remove affected rows")
        )
      } else {
        list(
          list(action = "fill_missing_mode", label = "Fill with mode"),
          list(action = "fill_missing_constant", label = "Fill with constant"),
          list(action = "add_missing_indicator", label = "Add missing indicator"),
          list(action = "remove_rows_missing", label = "Remove affected rows")
        )
      }
    },
    high_missing_column = {
      list(
        list(action = "drop_column", label = "Drop this column"),
        list(action = "drop_high_missing_columns", label = "Drop all high-missing columns"),
        list(action = "fill_missing_constant", label = "Fill with constant")
      )
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
          list(action = "convert_to_factor", label = "Convert to factor"),
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
        list(action = "winsorize_column", label = "Winsorize extreme values"),
        list(action = "robust_scale_column", label = "Robust scale using median and IQR"),
        list(action = "remove_outliers", label = "Remove outlier rows")
      )
    },
    invalid_range = {
      list(
        list(action = "replace_invalid_with_na", label = "Replace invalid values with NA"),
        list(action = "replace_invalid_with_median", label = "Replace invalid values with median"),
        list(action = "clip_to_range", label = "Clip values to valid range"),
        list(action = "remove_rows_invalid_range", label = "Remove invalid rows")
      )
    },
    empty_strings = {
      list(
        list(action = "trim_whitespace", label = "Trim whitespace"),
        list(action = "empty_strings_to_na", label = "Convert empty strings to NA"),
        list(action = "fill_missing_constant", label = "Replace with constant placeholder")
      )
    },
    skewed_distribution = {
      list(
        list(action = "log_transform", label = "Apply log transform"),
        list(action = "sqrt_transform", label = "Apply square-root transform"),
        list(action = "quantile_bin_column", label = "Bin into quantiles"),
        list(action = "standardize_column", label = "Standardize values"),
        list(action = "robust_scale_column", label = "Robust scale values"),
        list(action = "normalize_column", label = "Normalize to 0-1"),
        list(action = "no_change", label = "Keep as-is")
      )
    },
    high_cardinality = {
      list(
        list(action = "group_rare_categories", label = "Group rare categories"),
        list(action = "merge_categories", label = "Merge categories manually"),
        list(action = "lowercase_column", label = "Lowercase categories"),
        list(action = "label_encode_column", label = "Label encode categories"),
        list(action = "one_hot_encode_column", label = "One-hot encode categories"),
        list(action = "no_change", label = "Keep as-is")
      )
    },
    high_correlation = {
      list(
        list(action = "drop_column", label = "Drop this correlated column"),
        list(action = "drop_correlated_features", label = "Drop highly correlated features"),
        list(action = "no_change", label = "Keep both columns")
      )
    },
    list(list(action = "no_change", label = "No change"))
  )
}

recommend_best_fix <- function(issue, options) {
  preferred <- switch(
    issue$issue_type,
    missing_values = if ((issue$details$column_kind %||% "numeric") == "numeric") "fill_missing_median" else "fill_missing_mode",
    high_missing_column = "drop_column",
    duplicates = "remove_duplicates",
    type_mismatch = if (!is.null(issue$details$target_type) && identical(issue$details$target_type, "Date")) "convert_to_date" else "convert_to_numeric",
    outliers = "cap_outliers",
    invalid_range = "replace_invalid_with_na",
    empty_strings = "empty_strings_to_na",
    skewed_distribution = "log_transform",
    high_cardinality = "group_rare_categories",
    high_correlation = "drop_column",
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
    fill_missing_constant = "A constant fallback is useful when you want explicit placeholder values.",
    add_missing_indicator = "A missingness flag preserves information that values were absent.",
    drop_column = "Dropping the column is often the cleanest option when the feature is weak or too incomplete.",
    drop_high_missing_columns = "This removes columns that are too sparse to contribute reliably.",
    remove_duplicates = "Duplicate rows distort counts and should usually be removed.",
    convert_to_numeric = "Converting the column preserves usable numeric values for analysis.",
    convert_to_date = "Date conversion enables validation and time-based analysis.",
    convert_to_factor = "Factor conversion can help downstream handling of categorical labels in R.",
    cap_outliers = "Capping keeps rows while reducing the distortion from extreme values.",
    winsorize_column = "Winsorization softens extremes without discarding records entirely.",
    robust_scale_column = "Robust scaling uses median and IQR, which is more stable with outliers.",
    replace_invalid_with_na = "Replacing impossible values with NA avoids introducing false data.",
    replace_invalid_with_median = "Median replacement keeps the value valid while limiting distortion.",
    clip_to_range = "Clipping enforces known business bounds directly.",
    trim_whitespace = "Whitespace cleanup often fixes category fragmentation before stronger changes.",
    empty_strings_to_na = "Empty strings should be standardized so missingness can be handled consistently.",
    log_transform = "Log transform reduces skewness while preserving ordering.",
    sqrt_transform = "Square-root transform is a gentler option for moderately skewed distributions.",
    quantile_bin_column = "Quantile bins can reduce skew and create easier-to-compare buckets.",
    standardize_column = "Standardization makes numeric scales comparable across columns.",
    normalize_column = "Normalization compresses the values to a consistent 0-1 range.",
    group_rare_categories = "Grouping rare categories reduces fragmentation in categorical analysis.",
    merge_categories = "Manual merging is useful when different labels represent the same concept.",
    lowercase_column = "Lowercasing helps unify categories with inconsistent casing.",
    label_encode_column = "Label encoding converts categories to integers for model-ready features.",
    one_hot_encode_column = "One-hot encoding avoids imposing a false numeric order on categories.",
    drop_correlated_features = "Dropping redundant features can simplify the model and reduce multicollinearity.",
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
