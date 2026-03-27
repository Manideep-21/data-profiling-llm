required_packages <- c(
  "ggplot2",
  "httr",
  "jsonlite"
)

missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
} else {
  message("All required packages are already installed.")
}

invisible(required_packages)
