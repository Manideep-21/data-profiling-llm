save_plot <- function(plot, file_path, width = 10, height = 6) {
  dir.create(dirname(file_path), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(filename = file_path, plot = plot, width = width, height = height, dpi = 140)
  file_path
}

plot_missing_values <- function(data, file_path) {
  missing_df <- data.frame(
    column = names(data),
    missing_pct = vapply(data, function(column) round(mean(is.na(column)) * 100, 2), numeric(1))
  )

  plot <- ggplot2::ggplot(missing_df, ggplot2::aes(x = stats::reorder(column, missing_pct), y = missing_pct)) +
    ggplot2::geom_col(fill = "#d55e00") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Missing Values by Column",
      x = "Column",
      y = "Missing (%)"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  save_plot(plot, file_path, width = 8, height = 5)
}

plot_numeric_distribution <- function(data, column, file_path) {
  values <- safe_numeric(data[[column]])
  plot_df <- data.frame(value = values)
  plot <- ggplot2::ggplot(plot_df, ggplot2::aes(x = value)) +
    ggplot2::geom_histogram(bins = 20, fill = "#0072b2", color = "white", na.rm = TRUE) +
    ggplot2::geom_density(color = "#cc79a7", linewidth = 1, na.rm = TRUE) +
    ggplot2::labs(
      title = paste("Distribution:", column),
      x = column,
      y = "Count"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  save_plot(plot, file_path, width = 8, height = 5)
}

plot_numeric_boxplot <- function(data, column, file_path) {
  values <- safe_numeric(data[[column]])
  plot_df <- data.frame(column = column, value = values)
  plot <- ggplot2::ggplot(plot_df, ggplot2::aes(x = column, y = value)) +
    ggplot2::geom_boxplot(fill = "#009e73", outlier.color = "#d55e00", na.rm = TRUE) +
    ggplot2::labs(
      title = paste("Box Plot:", column),
      x = NULL,
      y = column
    ) +
    ggplot2::theme_minimal(base_size = 12)

  save_plot(plot, file_path, width = 5, height = 5)
}

plot_categorical_bar <- function(data, column, file_path, top_n = 10) {
  values <- as.character(data[[column]])
  values[is.na(values)] <- "Missing"
  freq <- sort(table(values), decreasing = TRUE)
  freq <- utils::head(freq, top_n)
  plot_df <- data.frame(category = names(freq), count = as.integer(freq), stringsAsFactors = FALSE)

  plot <- ggplot2::ggplot(plot_df, ggplot2::aes(x = stats::reorder(category, count), y = count)) +
    ggplot2::geom_col(fill = "#56b4e9") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = paste("Top Categories:", column),
      x = "Category",
      y = "Count"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  save_plot(plot, file_path, width = 8, height = 5)
}

plot_data_types <- function(data, file_path) {
  classes <- vapply(data, function(column) class(column)[1], character(1))
  type_df <- as.data.frame(table(classes), stringsAsFactors = FALSE)
  names(type_df) <- c("type", "count")

  plot <- ggplot2::ggplot(type_df, ggplot2::aes(x = type, y = count, fill = type)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::labs(
      title = "Column Type Summary",
      x = "Type",
      y = "Count"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  save_plot(plot, file_path, width = 7, height = 5)
}

plot_issue_summary <- function(issues, file_path) {
  issue_types <- if (length(issues) == 0) character(0) else vapply(issues, function(issue) issue$issue_type, character(1))
  issue_df <- as.data.frame(table(issue_types), stringsAsFactors = FALSE)
  names(issue_df) <- c("issue_type", "count")

  if (nrow(issue_df) == 0) {
    issue_df <- data.frame(issue_type = "none", count = 0, stringsAsFactors = FALSE)
  }

  plot <- ggplot2::ggplot(issue_df, ggplot2::aes(x = stats::reorder(issue_type, count), y = count)) +
    ggplot2::geom_col(fill = "#e69f00") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Detected Issues Summary",
      x = "Issue Type",
      y = "Count"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  save_plot(plot, file_path, width = 8, height = 5)
}

plot_score_comparison <- function(score_before, score_after, file_path) {
  score_df <- data.frame(
    stage = c("Before", "After"),
    score = c(score_before, score_after)
  )

  plot <- ggplot2::ggplot(score_df, ggplot2::aes(x = stage, y = score, fill = stage)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::ylim(0, 100) +
    ggplot2::labs(
      title = "Data Quality Score Comparison",
      x = NULL,
      y = "Score"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  save_plot(plot, file_path, width = 6, height = 4)
}

generate_visualizations <- function(data, issues, score_before = NULL, score_after = NULL, output_dir = CONFIG$visualization_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  plots <- list()

  plots$missing_values <- plot_missing_values(data, file.path(output_dir, "missing_values.png"))
  plots$data_types <- plot_data_types(data, file.path(output_dir, "data_types.png"))
  plots$issue_summary <- plot_issue_summary(issues, file.path(output_dir, "issue_summary.png"))

  numeric_columns <- names(data)[vapply(data, function(column) is.numeric(column) || inherits(column, "integer"), logical(1))]
  categorical_columns <- names(data)[vapply(data, function(column) is.character(column) || is.factor(column), logical(1))]

  plots$numeric_distributions <- list()
  plots$numeric_boxplots <- list()
  plots$categorical_bars <- list()

  if (length(numeric_columns) > 0) {
    for (column in numeric_columns) {
      plots$numeric_distributions[[column]] <- plot_numeric_distribution(
        data,
        column,
        file.path(output_dir, paste0(column, "_distribution.png"))
      )
      plots$numeric_boxplots[[column]] <- plot_numeric_boxplot(
        data,
        column,
        file.path(output_dir, paste0(column, "_boxplot.png"))
      )
    }
  }

  if (length(categorical_columns) > 0) {
    for (column in categorical_columns) {
      plots$categorical_bars[[column]] <- plot_categorical_bar(
        data,
        column,
        file.path(output_dir, paste0(column, "_bar.png"))
      )
    }
  }

  if (!is.null(score_before) && !is.null(score_after)) {
    plots$score_comparison <- plot_score_comparison(
      score_before,
      score_after,
      file.path(output_dir, "score_comparison.png")
    )
  }

  plots
}
