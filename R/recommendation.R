get_recommended_fixes <- function(suggestions) {
  lapply(suggestions$suggestions, function(item) {
    list(
      issue_id = item$issue_id,
      column = item$issue$column,
      action = item$recommended$action
    )
  })
}
