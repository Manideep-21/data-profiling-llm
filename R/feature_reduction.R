get_numeric_frame <- function(data) {
  numeric_columns <- names(data)[vapply(data, function(column) {
    is.numeric(column) || inherits(column, "integer")
  }, logical(1))]

  if (length(numeric_columns) == 0) {
    return(data.frame())
  }

  data[, numeric_columns, drop = FALSE]
}

compute_correlation_analysis <- function(data, threshold = CONFIG$correlation_threshold) {
  numeric_data <- get_numeric_frame(data)

  if (ncol(numeric_data) < 2) {
    return(list(
      matrix = NULL,
      high_pairs = data.frame(),
      suggested_drops = character(0)
    ))
  }

  correlation_matrix <- stats::cor(numeric_data, use = "pairwise.complete.obs")
  high_pairs <- data.frame(
    feature_a = character(0),
    feature_b = character(0),
    correlation = numeric(0),
    stringsAsFactors = FALSE
  )

  suggested_drops <- character(0)
  for (i in seq_len(ncol(correlation_matrix) - 1)) {
    for (j in seq((i + 1), ncol(correlation_matrix))) {
      corr_value <- correlation_matrix[i, j]
      if (is.finite(corr_value) && abs(corr_value) >= threshold) {
        high_pairs <- rbind(
          high_pairs,
          data.frame(
            feature_a = colnames(correlation_matrix)[i],
            feature_b = colnames(correlation_matrix)[j],
            correlation = round(corr_value, 4),
            stringsAsFactors = FALSE
          )
        )
        suggested_drops <- unique(c(suggested_drops, colnames(correlation_matrix)[j]))
      }
    }
  }

  list(
    matrix = correlation_matrix,
    high_pairs = high_pairs,
    suggested_drops = suggested_drops
  )
}

save_correlation_heatmap <- function(correlation_matrix, output_path = CONFIG$correlation_heatmap_path) {
  if (is.null(correlation_matrix) || ncol(correlation_matrix) < 2) {
    return(invisible(NULL))
  }

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  grDevices::png(filename = output_path, width = 1200, height = 900, res = 140)
  graphics::par(mar = c(8, 8, 4, 2))
  stats::heatmap(
    correlation_matrix,
    Rowv = NA,
    Colv = NA,
    scale = "none",
    col = grDevices::colorRampPalette(c("#b2182b", "#f7f7f7", "#2166ac"))(100),
    margins = c(10, 10),
    main = "Correlation Heatmap"
  )
  grDevices::dev.off()
  invisible(output_path)
}
