user_select <- function(suggestions, auto_approve = CONFIG$auto_approve_recommended) {
  if (length(suggestions$suggestions) == 0) {
    return(list())
  }

  if (!CONFIG$interactive_mode || isTRUE(auto_approve)) {
    return(get_recommended_fixes(suggestions))
  }

  selected <- list()
  for (item in suggestions$suggestions) {
    cat("\nIssue:", item$issue$message, "\n")
    cat("Explanation:", item$explanation, "\n")

    for (i in seq_along(item$options)) {
      option <- item$options[[i]]
      marker <- if (identical(option$action, item$recommended$action)) " (recommended)" else ""
      cat(sprintf("%d. %s%s\n", i, option$label, marker))
    }

    answer <- readline("Apply recommended fix? (Y/N): ")
    choice <- if (tolower(trimws(answer)) %in% c("y", "yes", "")) {
      item$recommended$action
    } else {
      option_number <- as.integer(readline("Choose option number: "))
      item$options[[option_number]]$action
    }

    selected[[length(selected) + 1]] <- list(
      issue_id = item$issue_id,
      column = item$issue$column,
      action = choice
    )
  }

  selected
}
