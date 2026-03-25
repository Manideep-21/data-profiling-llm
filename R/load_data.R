load_data <- function(file_path = CONFIG$data_path) {
  if (!file.exists(file_path)) {
    stop(sprintf("Dataset not found at '%s'.", file_path))
  }

  data <- utils::read.csv(
    file_path,
    stringsAsFactors = FALSE,
    na.strings = c("", "NA", "N/A", "NULL")
  )

  attr(data, "source_path") <- normalizePath(file_path, mustWork = FALSE)
  data
}
