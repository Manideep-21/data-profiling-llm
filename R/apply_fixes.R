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

fill_missing_constant <- function(data, column, constant = "Unknown") {
  values <- data[[column]]
  values[is.na(values)] <- constant
  data[[column]] <- values
  data
}

add_missing_indicator <- function(data, column) {
  indicator_name <- paste0(column, "_missing_flag")
  data[[indicator_name]] <- as.integer(is.na(data[[column]]))
  data
}

drop_column <- function(data, column) {
  if (column %in% names(data)) {
    data[[column]] <- NULL
  }
  data
}

drop_high_missing_columns <- function(data, threshold_pct = CONFIG$missing_drop_threshold_pct) {
  missing_pct <- vapply(data, function(column) mean(is.na(column)) * 100, numeric(1))
  drop_columns <- names(missing_pct)[missing_pct >= threshold_pct]
  if (length(drop_columns) == 0) {
    return(data)
  }

  data[, setdiff(names(data), drop_columns), drop = FALSE]
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
  } else if (identical(target_type, "factor")) {
    data[[column]] <- as.factor(data[[column]])
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
  range_value <- max(values, na.rm = TRUE) - min(values, na.rm = TRUE)
  if (!is.finite(range_value) || range_value == 0) {
    return(data)
  }

  data[[column]] <- (values - min(values, na.rm = TRUE)) / range_value
  data
}

standardize_column <- function(data, column) {
  values <- safe_numeric(data[[column]])
  sd_value <- stats::sd(values, na.rm = TRUE)
  if (!is.finite(sd_value) || sd_value == 0) {
    return(data)
  }

  data[[column]] <- (values - mean(values, na.rm = TRUE)) / sd_value
  data
}

robust_scale_column <- function(data, column) {
  values <- safe_numeric(data[[column]])
  med <- stats::median(values, na.rm = TRUE)
  q1 <- stats::quantile(values, 0.25, na.rm = TRUE, names = FALSE)
  q3 <- stats::quantile(values, 0.75, na.rm = TRUE, names = FALSE)
  iqr_value <- q3 - q1
  if (!is.finite(iqr_value) || iqr_value == 0) {
    return(data)
  }

  data[[column]] <- (values - med) / iqr_value
  data
}

winsorize_column <- function(data, column, lower_quantile = 0.05, upper_quantile = 0.95) {
  values <- safe_numeric(data[[column]])
  lower <- stats::quantile(values, lower_quantile, na.rm = TRUE, names = FALSE)
  upper <- stats::quantile(values, upper_quantile, na.rm = TRUE, names = FALSE)
  data[[column]] <- pmin(pmax(values, lower), upper)
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

replace_invalid_with_median <- function(data, column) {
  values <- safe_numeric(data[[column]])
  valid_values <- values

  if (identical(column, "Age")) {
    invalid <- !is.na(values) & (values < 0 | values > 120)
    valid_values[invalid] <- NA
  } else if (identical(column, "Score")) {
    invalid <- !is.na(values) & (values < 0 | values > 100)
    valid_values[invalid] <- NA
  } else {
    invalid <- logical(length(values))
  }

  replacement <- stats::median(valid_values, na.rm = TRUE)
  values[invalid] <- replacement
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

trim_whitespace <- function(data, column) {
  if (!is.character(data[[column]])) {
    return(data)
  }

  data[[column]] <- trimws(data[[column]])
  data
}

titlecase_column <- function(data, column) {
  if (!is.character(data[[column]])) {
    return(data)
  }

  values <- tolower(trimws(data[[column]]))
  split_values <- strsplit(values, "\\s+")
  titled <- vapply(split_values, function(parts) {
    paste(tools::toTitleCase(parts), collapse = " ")
  }, character(1))
  data[[column]] <- titled
  data
}

lowercase_column <- function(data, column) {
  if (!is.character(data[[column]])) {
    return(data)
  }

  data[[column]] <- tolower(data[[column]])
  data
}

uppercase_column <- function(data, column) {
  if (!is.character(data[[column]])) {
    return(data)
  }

  data[[column]] <- toupper(data[[column]])
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

merge_categories <- function(data, column, mapping = list()) {
  values <- data[[column]]
  if (!is.character(values) || length(mapping) == 0) {
    return(data)
  }

  for (target in names(mapping)) {
    values[values %in% mapping[[target]]] <- target
  }

  data[[column]] <- values
  data
}

sanitize_dummy_name <- function(x) {
  cleaned <- gsub("[^A-Za-z0-9]+", "_", x)
  cleaned <- gsub("^_+|_+$", "", cleaned)
  ifelse(cleaned == "", "value", cleaned)
}

label_encode_column <- function(data, column, na_label = "Missing") {
  values <- as.character(data[[column]])
  values[is.na(values)] <- na_label
  unique_values <- sort(unique(values))
  mapping <- stats::setNames(seq_along(unique_values), unique_values)
  encoded <- unname(mapping[values])
  data[[paste0(column, "_label")]] <- as.integer(encoded)
  attr(data, paste0(column, "_label_mapping")) <- mapping
  data
}

one_hot_encode_column <- function(data, column, drop_original = FALSE, na_label = "Missing") {
  values <- as.character(data[[column]])
  values[is.na(values)] <- na_label
  categories <- sort(unique(values))

  for (category in categories) {
    dummy_name <- paste0(column, "_", sanitize_dummy_name(category))
    data[[dummy_name]] <- as.integer(values == category)
  }

  if (isTRUE(drop_original)) {
    data[[column]] <- NULL
  }

  data
}

log_transform <- function(data, column) {
  values <- safe_numeric(data[[column]])
  min_value <- suppressWarnings(min(values, na.rm = TRUE))
  offset <- if (is.finite(min_value) && min_value <= 0) abs(min_value) + 1 else 1
  data[[column]] <- log(values + offset)
  data
}

sqrt_transform <- function(data, column) {
  values <- safe_numeric(data[[column]])
  min_value <- suppressWarnings(min(values, na.rm = TRUE))
  offset <- if (is.finite(min_value) && min_value < 0) abs(min_value) else 0
  data[[column]] <- sqrt(values + offset)
  data
}

quantile_bin_column <- function(data, column, bins = 4) {
  values <- safe_numeric(data[[column]])
  valid <- values[!is.na(values)]
  if (length(unique(valid)) < 2) {
    return(data)
  }

  probs <- seq(0, 1, length.out = bins + 1)
  breaks <- unique(stats::quantile(valid, probs = probs, na.rm = TRUE, names = FALSE))
  if (length(breaks) < 3) {
    return(data)
  }

  data[[paste0(column, "_bin")]] <- cut(values, breaks = breaks, include.lowest = TRUE, ordered_result = TRUE)
  data
}

drop_correlated_features <- function(data, threshold = CONFIG$correlation_threshold, preserve = character(0)) {
  analysis <- compute_correlation_analysis(data, threshold = threshold)
  drop_columns <- setdiff(analysis$suggested_drops, preserve)
  if (length(drop_columns) == 0) {
    return(data)
  }

  data[, setdiff(names(data), drop_columns), drop = FALSE]
}

drop_constant_column <- function(data, column) {
  values <- data[[column]]
  unique_non_missing <- unique(values[!is.na(values)])
  if (length(unique_non_missing) <= 1) {
    data[[column]] <- NULL
  }
  data
}

clip_to_range <- function(data, column, lower = -Inf, upper = Inf) {
  values <- safe_numeric(data[[column]])
  data[[column]] <- pmin(pmax(values, lower), upper)
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
    fill_missing_constant = fill_missing_constant(data, column),
    add_missing_indicator = add_missing_indicator(data, column),
    drop_column = drop_column(data, column),
    drop_high_missing_columns = drop_high_missing_columns(data),
    remove_rows_missing = remove_rows(data, which(is.na(data[[column]]))),
    remove_duplicates = remove_duplicates(data),
    convert_to_numeric = convert_type(data, column, "numeric"),
    convert_to_date = convert_type(data, column, "Date"),
    convert_to_factor = convert_type(data, column, "factor"),
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
    winsorize_column = winsorize_column(data, column),
    normalize_column = normalize_column(data, column),
    standardize_column = standardize_column(data, column),
    robust_scale_column = robust_scale_column(data, column),
    replace_invalid_with_na = replace_invalid_with_na(data, column),
    replace_invalid_with_median = replace_invalid_with_median(data, column),
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
    trim_whitespace = trim_whitespace(data, column),
    lowercase_column = lowercase_column(data, column),
    uppercase_column = uppercase_column(data, column),
    titlecase_column = titlecase_column(data, column),
    group_rare_categories = group_rare_categories(data, column),
    merge_categories = merge_categories(data, column),
    label_encode_column = label_encode_column(data, column),
    one_hot_encode_column = one_hot_encode_column(data, column),
    log_transform = log_transform(data, column),
    sqrt_transform = sqrt_transform(data, column),
    quantile_bin_column = quantile_bin_column(data, column),
    drop_correlated_features = drop_correlated_features(data, preserve = column),
    clip_to_range = {
      if (identical(column, "Age")) {
        clip_to_range(data, column, 0, 120)
      } else if (identical(column, "Score")) {
        clip_to_range(data, column, 0, 100)
      } else {
        clip_to_range(data, column)
      }
    },
    drop_constant_column = drop_constant_column(data, column),
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
