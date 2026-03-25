safe_numeric <- function(x) {
  if (is.numeric(x)) {
    return(x)
  }

  suppressWarnings(as.numeric(x))
}

profile_column <- function(column, name) {
  total <- length(column)
  missing_count <- sum(is.na(column))
  missing_pct <- round((missing_count / max(total, 1)) * 100, 2)
  unique_count <- length(unique(column[!is.na(column)]))

  profile <- list(
    name = name,
    detected_type = class(column)[1],
    missing_count = missing_count,
    missing_pct = missing_pct,
    unique_count = unique_count
  )

  numeric_values <- safe_numeric(column)
  numeric_valid <- numeric_values[!is.na(numeric_values)]

  if (length(numeric_valid) > 0 && (is.numeric(column) || sum(!is.na(numeric_values)) >= ceiling(0.7 * sum(!is.na(column))))) {
    q1 <- stats::quantile(numeric_valid, 0.25, na.rm = TRUE, names = FALSE)
    q3 <- stats::quantile(numeric_valid, 0.75, na.rm = TRUE, names = FALSE)
    iqr_value <- q3 - q1
    lower_bound <- q1 - 1.5 * iqr_value
    upper_bound <- q3 + 1.5 * iqr_value
    outlier_count <- sum(numeric_valid < lower_bound | numeric_valid > upper_bound, na.rm = TRUE)

    profile$summary <- list(
      mean = round(mean(numeric_valid, na.rm = TRUE), 3),
      median = round(stats::median(numeric_valid, na.rm = TRUE), 3),
      min = min(numeric_valid, na.rm = TRUE),
      max = max(numeric_valid, na.rm = TRUE),
      sd = round(stats::sd(numeric_valid, na.rm = TRUE), 3),
      outlier_count = outlier_count,
      skewness_hint = if (length(numeric_valid) >= 3) {
        mean(numeric_valid, na.rm = TRUE) - stats::median(numeric_valid, na.rm = TRUE)
      } else {
        0
      }
    )
  } else {
    freq <- sort(table(column, useNA = "no"), decreasing = TRUE)
    top_values <- utils::head(freq, 5)

    profile$summary <- list(
      top_values = as.list(top_values),
      min_length = if (total > 0) min(nchar(as.character(column)), na.rm = TRUE) else NA,
      max_length = if (total > 0) max(nchar(as.character(column)), na.rm = TRUE) else NA
    )
  }

  profile
}

profile_data <- function(data) {
  columns <- lapply(names(data), function(name) profile_column(data[[name]], name))
  names(columns) <- names(data)

  list(
    dataset = list(
      rows = nrow(data),
      columns = ncol(data),
      duplicate_rows = sum(duplicated(data)),
      total_missing = sum(is.na(data))
    ),
    columns = columns
  )
}
