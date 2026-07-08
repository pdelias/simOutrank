# The four criteria of Table 2 in Delias et al. (2021), applied to the bundled
# illustrative_log. Nominal (Status, Satisfaction) criteria are built as
# precomputed match matrices from the case attributes; a veto of -1 disables
# discordance, as in the paper.
illustrative_sim <- function() {
  tr <- as_traces(illustrative_log, "case_id", "activity", "timestamp")
  ids <- tr$case_ids
  attrs <- tr$case_attributes

  match_matrix <- function(x) {
    m <- outer(x, x, "==") * 1
    dimnames(m) <- list(ids, ids)
    m
  }
  status_match       <- match_matrix(attrs$status)
  satisfaction_match <- match_matrix(attrs$satisfaction)

  criteria <- list(
    criterion(function(t) measure_activity_profile(t), "similarity",
              weight = 0.2, indifference = 0.7, similarity = 0.8, veto = 0.4,
              name = "Activities"),
    criterion(function(t) measure_edit_distance(t), "dissimilarity",
              weight = 0.2, indifference = 3, similarity = 2, veto = 6,
              name = "Transitions"),
    criterion(status_match, "similarity",
              weight = 0.3, indifference = 0, similarity = 1, veto = -1,
              name = "Status"),
    criterion(satisfaction_match, "similarity",
              weight = 0.3, indifference = 0, similarity = 1, veto = -1,
              name = "Satisfaction")
  )

  suppressMessages(outrank_similarity(tr, criteria))
}
