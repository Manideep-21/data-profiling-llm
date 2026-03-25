read_terminal_input <- function(prompt) {
  cat(prompt)
  flush.console()
  input <- readLines(file("stdin"), n = 1, warn = FALSE)
  if (length(input) == 0) {
    return("")
  }
  input[[1]]
}

choose_option <- function(item) {
  repeat {
    option_number <- suppressWarnings(as.integer(read_terminal_input("Choose option number: ")))
    if (!is.na(option_number) && option_number >= 1 && option_number <= length(item$options)) {
      return(item$options[[option_number]]$action)
    }
    cat("Please enter a valid option number.\n")
  }
}

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

    answer <- tolower(trimws(read_terminal_input("Apply recommended fix? (Y/N): ")))
    choice <- if (tolower(trimws(answer)) %in% c("y", "yes", "")) {
      item$recommended$action
    } else {
      choose_option(item)
    }

    selected[[length(selected) + 1]] <- list(
      issue_id = item$issue_id,
      column = item$issue$column,
      action = choice
    )
  }

  selected
}
