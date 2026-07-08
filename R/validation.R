# Cluster validation and joining memberships back onto an event log.

#' Internal cluster validity indices
#'
#' `validate_clusters()` reports the connectivity and Dunn index of a
#' clustering, computed on the dissimilarity `as.dist(1 - S)`.
#'
#' @details
#' Connectivity (to be minimised) and the Dunn index (to be maximised) are
#' obtained from the \pkg{clValid} package. If \pkg{clValid} is not installed,
#' the function returns `NA` values with an informative message.
#'
#' @param clust An `outrank_clust` object from [cluster_traces()].
#' @return A named numeric vector with `connectivity` and `dunn`.
#' @examples
#' m <- matrix(0.1, 6, 6); m[1:3, 1:3] <- 0.9; m[4:6, 4:6] <- 0.9
#' diag(m) <- 1; dimnames(m) <- list(1:6, 1:6)
#' crit <- criterion(m, "similarity", indifference = 0.3, similarity = 0.95)
#' tr <- as_traces(data.frame(case = as.character(1:6), act = "x",
#'                            ts = as.POSIXct("2020-01-01")),
#'                 "case", "act", "ts")
#' clust <- cluster_traces(outrank_similarity(tr, crit), k = 2, seed = 1)
#' validate_clusters(clust)
#' @export
validate_clusters <- function(clust) {
  if (!inherits(clust, "outrank_clust")) {
    stop("`clust` must be an outrank_clust object (see cluster_traces()).",
         call. = FALSE)
  }
  d <- stats::as.dist(1 - clust$sim$S)
  memb <- clust$memberships
  if (!requireNamespace("clValid", quietly = TRUE)) {
    message("Package 'clValid' is not installed; connectivity and Dunn index ",
            "are unavailable. Install it to enable validate_clusters().")
    return(c(connectivity = NA_real_, dunn = NA_real_))
  }
  c(connectivity = clValid::connectivity(distance = d, clusters = memb),
    dunn = clValid::dunn(distance = d, clusters = memb))
}

#' Join cluster memberships onto an event log
#'
#' `augment_log()` adds a `.cluster` column to an event log, mapping every
#' event to the cluster of its case.
#'
#' @param clust An `outrank_clust` object from [cluster_traces()].
#' @param log The event-log `data.frame` the clustering came from.
#' @return `log` with an added integer `.cluster` column (`NA` for cases absent
#'   from the clustering, e.g. trimmed outliers).
#' @details The case-id column is detected as the column of `log` whose values
#'   cover all clustered case ids; a message reports which column was used.
#' @examples
#' log <- data.frame(case = rep(c("a", "b", "c", "d"), each = 2),
#'                   act = rep(c("x", "y"), 4),
#'                   ts = as.POSIXct("2020-01-01") + (0:7) * 60)
#' m <- matrix(0.1, 4, 4); m[1:2, 1:2] <- 0.9; m[3:4, 3:4] <- 0.9
#' diag(m) <- 1; dimnames(m) <- list(c("a", "b", "c", "d"), c("a", "b", "c", "d"))
#' crit <- criterion(m, "similarity", indifference = 0.3, similarity = 0.95)
#' tr <- as_traces(log, "case", "act", "ts")
#' clust <- cluster_traces(outrank_similarity(tr, crit), k = 2, seed = 1)
#' augment_log(clust, log)
#' @export
augment_log <- function(clust, log) {
  if (!inherits(clust, "outrank_clust")) {
    stop("`clust` must be an outrank_clust object (see cluster_traces()).",
         call. = FALSE)
  }
  if (!is.data.frame(log)) {
    stop("`log` must be a data frame (the event log).", call. = FALSE)
  }
  memb <- clust$memberships
  ids <- names(memb)

  covers <- vapply(log, function(col) all(ids %in% as.character(col)),
                   logical(1L))
  if (!any(covers)) {
    stop("No column of `log` contains all clustered case ids.", call. = FALSE)
  }
  case_col <- names(log)[which(covers)[1L]]
  message("Joining on case-id column '", case_col, "'.")

  log[[".cluster"]] <- unname(memb[as.character(log[[case_col]])])
  log
}
