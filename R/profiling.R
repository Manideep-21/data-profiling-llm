safe_numeric <- function(x) {
  if (is.numeric(x)) {
    return(x)
  }

  suppressWarnings(as.numeric(x))
}

compute_mode <- function(x) {
  observed <- x[!is.na(x)]
  if (length(observed) == 0) {
    return(NA)
  }

  freq <- sort(table(observed), decreasing = TRUE)
  names(freq)[1]
}

profile_numeric_column <- function(column) {
  numeric_values <- safe_numeric(column)
  valid <- numeric_values[!is.na(numeric_values)]

  if (length(valid) == 0) {
    return(list(
      subtype = "numeric",
      mean = NA,
      median = NA,
      min = NA,
      max = NA,
      sd = NA,
      variance = NA,
      q1 = NA,
      q3 = NA,
      p05 = NA,
      p95 = NA,
      iqr = NA,
      outlier_count = 0,
      zero_count = 0,
      negative_count = 0,
      infinite_count = sum(is.infinite(numeric_values), na.rm = TRUE),
      skewness_hint = 0,
      constant_column = FALSE,
      near_zero_variance = FALSE,
      recommended_visual = "histogram_boxplot"
    ))
  }

  q1 <- stats::quantile(valid, 0.25, na.rm = TRUE, names = FALSE)
  q3 <- stats::quantile(valid, 0.75, na.rm = TRUE, names = FALSE)
  iqr_value <- q3 - q1
  lower_bound <- q1 - 1.5 * iqr_value
  upper_bound <- q3 + 1.5 * iqr_value
  outlier_count <- sum(valid < lower_bound | valid > upper_bound, na.rm = TRUE)
  sd_value <- stats::sd(valid, na.rm = TRUE)
  variance_value <- stats::var(valid, na.rm = TRUE)
  unique_count <- length(unique(valid))

  list(
    subtype = "numeric",
    mean = round(mean(valid, na.rm = TRUE), 3),
    median = round(stats::median(valid, na.rm = TRUE), 3),
    min = min(valid, na.rm = TRUE),
    max = max(valid, na.rm = TRUE),
    sd = round(sd_value, 3),
    variance = round(variance_value, 3),
    q1 = round(q1, 3),
    q3 = round(q3, 3),
    p05 = round(stats::quantile(valid, 0.05, na.rm = TRUE, names = FALSE), 3),
    p95 = round(stats::quantile(valid, 0.95, na.rm = TRUE, names = FALSE), 3),
    iqr = round(iqr_value, 3),
    outlier_count = outlier_count,
    zero_count = sum(valid == 0, na.rm = TRUE),
    negative_count = sum(valid < 0, na.rm = TRUE),
    infinite_count = sum(is.infinite(numeric_values), na.rm = TRUE),
    skewness_hint = round(mean(valid, na.rm = TRUE) - stats::median(valid, na.rm = TRUE), 3),
    constant_column = unique_count <= 1,
    near_zero_variance = isTRUE(unique_count <= 2 || (!is.na(sd_value) && is.finite(sd_value) && sd_value < 1e-6)),
    recommended_visual = "histogram_boxplot"
  )
}

profile_date_column <- function(column) {
  parsed <- if (inherits(column, "Date")) column else safe_parse_dates(column)
  valid <- parsed[!is.na(parsed)]

  list(
    subtype = "date",
    valid_date_count = length(valid),
    invalid_date_count = sum(is.na(parsed) & !is.na(column)),
    min_date = if (length(valid) > 0) as.character(min(valid)) else NA,
    max_date = if (length(valid) > 0) as.character(max(valid)) else NA,
    span_days = if (length(valid) > 0) as.integer(max(valid) - min(valid)) else NA,
    recommended_visual = "bar_or_time_series"
  )
}

profile_categorical_column <- function(column) {
  values <- as.character(column)
  trimmed <- trimws(values)
  observed <- values[!is.na(values)]
  freq <- sort(table(observed), decreasing = TRUE)
  top_values <- utils::head(freq, 5)
  mode_value <- compute_mode(values)
  mode_frequency <- if (length(freq) > 0) as.integer(freq[1]) else 0
  total_observed <- length(observed)
  rare_count <- if (length(freq) > 0) sum(freq < 2) else 0
  probabilities <- if (length(freq) > 0) as.numeric(freq) / sum(freq) else numeric(0)
  entropy <- if (length(probabilities) > 0) {
    -sum(probabilities * log2(probabilities))
  } else {
    0
  }

  list(
    subtype = "categorical",
    top_values = as.list(top_values),
    mode = mode_value,
    mode_frequency = mode_frequency,
    dominance_ratio = if (total_observed > 0) round(mode_frequency / total_observed, 3) else NA,
    rare_category_count = rare_count,
    entropy = round(entropy, 3),
    min_length = if (length(trimmed) > 0) min(nchar(trimmed), na.rm = TRUE) else NA,
    max_length = if (length(trimmed) > 0) max(nchar(trimmed), na.rm = TRUE) else NA,
    avg_length = if (length(trimmed) > 0) round(mean(nchar(trimmed), na.rm = TRUE), 3) else NA,
    whitespace_only_count = sum(!is.na(values) & trimmed == "", na.rm = TRUE),
    recommended_visual = "bar_chart"
  )
}

profile_column <- function(column, name) {
  total <- length(column)
  missing_count <- sum(is.na(column))
  missing_pct <- round((missing_count / max(total, 1)) * 100, 2)
  unique_count <- length(unique(column[!is.na(column)]))
  column_kind <- infer_column_kind(column)
  numeric_values <- safe_numeric(column)
  convertible_ratio <- if (sum(!is.na(column)) == 0) 0 else mean(!is.na(numeric_values[!is.na(column)]))

  profile <- list(
    name = name,
    detected_type = class(column)[1],
    inferred_kind = column_kind,
    missing_count = missing_count,
    missing_pct = missing_pct,
    unique_count = unique_count,
    uniqueness_ratio = if (sum(!is.na(column)) > 0) round(unique_count / sum(!is.na(column)), 3) else 0,
    nullable_risk = missing_pct >= CONFIG$missing_drop_threshold_pct,
    type_convertible_ratio = round(convertible_ratio, 3)
  )

  if (identical(column_kind, "numeric")) {
    profile$summary <- profile_numeric_column(column)
  } else if (identical(column_kind, "date") || identical(column_kind, "date_like")) {
    profile$summary <- profile_date_column(column)
  } else {
    profile$summary <- profile_categorical_column(column)
  }

  profile
}

profile_missingness <- function(data) {
  column_missing_pct <- vapply(data, function(column) round(mean(is.na(column)) * 100, 2), numeric(1))
  row_missing_counts <- rowSums(is.na(data))

  list(
    columns_above_threshold = names(column_missing_pct)[column_missing_pct >= CONFIG$missing_drop_threshold_pct],
    top_missing_columns = sort(column_missing_pct, decreasing = TRUE),
    max_row_missing = if (length(row_missing_counts) > 0) max(row_missing_counts) else 0,
    avg_row_missing = if (length(row_missing_counts) > 0) round(mean(row_missing_counts), 3) else 0
  )
}

profile_feature_reduction_candidates <- function(data) {
  columns <- names(data)
  constant_columns <- columns[vapply(data, function(column) {
    length(unique(column[!is.na(column)])) <= 1
  }, logical(1))]

  near_zero_variance_columns <- columns[vapply(data, function(column) {
    numeric_values <- safe_numeric(column)
    valid <- numeric_values[!is.na(numeric_values)]
    if (length(valid) == 0) {
      return(FALSE)
    }
    length(unique(valid)) <= 2 || (!is.na(stats::sd(valid, na.rm = TRUE)) && stats::sd(valid, na.rm = TRUE) < 1e-6)
  }, logical(1))]

  correlation_analysis <- compute_correlation_analysis(data)

  list(
    constant_columns = constant_columns,
    near_zero_variance_columns = unique(near_zero_variance_columns),
    high_correlation_pairs = correlation_analysis$high_pairs,
    suggested_correlation_drops = correlation_analysis$suggested_drops
  )
}

profile_data <- function(data) {
  columns <- lapply(names(data), function(name) profile_column(data[[name]], name))
  names(columns) <- names(data)

  list(
    dataset = list(
      rows = nrow(data),
      columns = ncol(data),
      duplicate_rows = sum(duplicated(data)),
      total_missing = sum(is.na(data)),
      missingness = profile_missingness(data),
      feature_reduction = profile_feature_reduction_candidates(data)
    ),
    columns = columns
  )
}
