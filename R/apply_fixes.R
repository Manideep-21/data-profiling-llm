fill_missing_mean <- function(data, column) {
  values <- safe_numeric(data[[column]])
  replacement <- mean(values, na.rm = TRUE)
  values[is.na(values)] <- replacement
  data[[column]] <- values
  data
}

fill_missing_median <- function(data, column) {
  values <- safe_numeric(data[[column]])
  replacement <- stats::median(values, na.rm = TRUE)
  values[is.na(values)] <- replacement
  data[[column]] <- values
  data
}

fill_missing_mode <- function(data, column) {
  values <- data[[column]]
  observed <- values[!is.na(values)]
  if (length(observed) == 0) {
    return(data)
  }

  freq <- sort(table(observed), decreasing = TRUE)
  replacement <- names(freq)[1]
  values[is.na(values)] <- replacement
  data[[column]] <- values
  data
}

remove_rows <- function(data, rows) {
  if (length(rows) == 0) {
    return(data)
  }

  data[-unique(rows), , drop = FALSE]
}

remove_duplicates <- function(data) {
  data[!duplicated(data), , drop = FALSE]
}

convert_type <- function(data, column, target_type) {
  if (identical(target_type, "numeric")) {
    data[[column]] <- safe_numeric(data[[column]])
  } else if (identical(target_type, "Date")) {
    data[[column]] <- safe_parse_dates(data[[column]])
  }

  data
}

remove_outliers <- function(data, column) {
  values <- safe_numeric(data[[column]])
  q1 <- stats::quantile(values, 0.25, na.rm = TRUE, names = FALSE)
  q3 <- stats::quantile(values, 0.75, na.rm = TRUE, names = FALSE)
  iqr_value <- q3 - q1
  lower <- q1 - 1.5 * iqr_value
  upper <- q3 + 1.5 * iqr_value
  keep <- is.na(values) | (values >= lower & values <= upper)
  data[keep, , drop = FALSE]
}

cap_outliers <- function(data, column) {
  values <- safe_numeric(data[[column]])
  q1 <- stats::quantile(values, 0.25, na.rm = TRUE, names = FALSE)
  q3 <- stats::quantile(values, 0.75, na.rm = TRUE, names = FALSE)
  iqr_value <- q3 - q1
  lower <- q1 - 1.5 * iqr_value
  upper <- q3 + 1.5 * iqr_value
  values <- pmin(pmax(values, lower), upper)
  data[[column]] <- values
  data
}

normalize_column <- function(data, column) {
  values <- safe_numeric(data[[column]])
  data[[column]] <- (values - min(values, na.rm = TRUE)) / (max(values, na.rm = TRUE) - min(values, na.rm = TRUE))
  data
}

replace_invalid_with_na <- function(data, column) {
  values <- safe_numeric(data[[column]])
  if (identical(column, "Age")) {
    values[values < 0 | values > 120] <- NA
  } else if (identical(column, "Score")) {
    values[values < 0 | values > 100] <- NA
  }
  data[[column]] <- values
  data
}

empty_strings_to_na <- function(data, column) {
  if (!is.character(data[[column]])) {
    return(data)
  }

  values <- trimws(data[[column]])
  values[values == ""] <- NA
  data[[column]] <- values
  data
}

group_rare_categories <- function(data, column, min_frequency = 2) {
  values <- data[[column]]
  if (!is.character(values)) {
    return(data)
  }

  freq <- table(values, useNA = "no")
  rare <- names(freq[freq < min_frequency])
  values[values %in% rare] <- "Other"
  data[[column]] <- values
  data
}

log_transform <- function(data, column) {
  values <- safe_numeric(data[[column]])
  min_value <- suppressWarnings(min(values, na.rm = TRUE))
  offset <- if (is.finite(min_value) && min_value <= 0) abs(min_value) + 1 else 1
  data[[column]] <- log(values + offset)
  data
}

apply_single_fix <- function(data, selected_fix, issues_by_id) {
  issue <- issues_by_id[[as.character(selected_fix$issue_id)]]
  action <- selected_fix$action
  column <- selected_fix$column

  switch(
    action,
    fill_missing_mean = fill_missing_mean(data, column),
    fill_missing_median = fill_missing_median(data, column),
    fill_missing_mode = fill_missing_mode(data, column),
    remove_rows_missing = remove_rows(data, which(is.na(data[[column]]))),
    remove_duplicates = remove_duplicates(data),
    convert_to_numeric = convert_type(data, column, "numeric"),
    convert_to_date = convert_type(data, column, "Date"),
    remove_rows_invalid_type = {
      if (!is.null(issue$details$target_type) && identical(issue$details$target_type, "Date")) {
        parsed <- safe_parse_dates(data[[column]])
        remove_rows(data, which(is.na(parsed) & !is.na(data[[column]])))
      } else {
        values <- safe_numeric(data[[column]])
        remove_rows(data, which(is.na(values) & !is.na(data[[column]])))
      }
    },
    remove_outliers = remove_outliers(data, column),
    cap_outliers = cap_outliers(data, column),
    replace_invalid_with_na = replace_invalid_with_na(data, column),
    remove_rows_invalid_range = {
      values <- safe_numeric(data[[column]])
      rows <- if (identical(column, "Age")) {
        which(!is.na(values) & (values < 0 | values > 120))
      } else if (identical(column, "Score")) {
        which(!is.na(values) & (values < 0 | values > 100))
      } else {
        integer(0)
      }
      remove_rows(data, rows)
    },
    empty_strings_to_na = empty_strings_to_na(data, column),
    group_rare_categories = group_rare_categories(data, column),
    log_transform = log_transform(data, column),
    no_change = data,
    data
  )
}

apply_fixes <- function(data, selected_fixes, issues) {
  issues_by_id <- setNames(issues, as.character(seq_along(issues)))
  cleaned <- data

  for (selected_fix in selected_fixes) {
    cleaned <- apply_single_fix(cleaned, selected_fix, issues_by_id)
  }

  cleaned
}
