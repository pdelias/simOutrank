# Outranking core: partial indices, aggregation and outrank_similarity().
#
# The partial-index formulas are written so that a single clamped linear
# expression covers both criterion directions; the direction only fixes the
# threshold ordering (validated when the criterion is built). All operations
# are on whole matrices -- there is no per-pair apply().

## Partial concordance c(a,b) for a measure matrix `v` (section 2).
##
## For thresholds indifference q and similarity s,
##   c = clamp( (v - q) / (s - q), 0, 1 ).
## With q < s (similarity direction) this ramps up from 0 at q to 1 at s; with
## s < q (dissimilarity direction) the same expression ramps the other way, so
## one formula serves both.
partial_concordance <- function(v, indifference, similarity) {
  pmin(pmax((v - indifference) / (similarity - indifference), 0), 1)
}

## Partial discordance d(a,b) for a measure matrix `v` (section 2).
##
## For thresholds indifference q and veto t,
##   d = clamp( (q - v) / (q - t), 0, 1 ),
## with a NULL veto contributing no discordance (d identically 0).
partial_discordance <- function(v, indifference, veto) {
  if (is.null(veto)) {
    return(array(0, dim = dim(v), dimnames = dimnames(v)))
  }
  pmin(pmax((indifference - v) / (indifference - veto), 0), 1)
}

## Per-criterion (1 - d)/(1 - c) factor, guarded so that criteria outside the
## discordance set J = {j : d_j > c_j} contribute a neutral factor of 1. The
## d <= c mask also covers the c = 1 case (where d > c is impossible and the
## raw ratio would divide by zero).
credibility_factor <- function(concordance, discordance) {
  factor <- (1 - discordance) / (1 - concordance)
  factor[discordance <= concordance] <- 1
  factor
}

## Resolve a criterion's measure to a matrix ordered on `ids`.
eval_measure <- function(measure, traces, ids) {
  v <- if (is.function(measure)) measure(traces) else measure
  v <- as.matrix(v)
  if (!is.numeric(v)) {
    stop("A criterion measure must yield a numeric matrix.", call. = FALSE)
  }
  if (!is.null(rownames(v)) && !is.null(colnames(v))) {
    if (!all(ids %in% rownames(v)) || !all(ids %in% colnames(v))) {
      stop("A criterion measure matrix is missing some case ids.",
           call. = FALSE)
    }
    v <- v[ids, ids, drop = FALSE]
  } else if (all(dim(v) == length(ids))) {
    dimnames(v) <- list(ids, ids)
  } else {
    stop("A criterion measure matrix does not match the number of cases.",
         call. = FALSE)
  }
  v
}

#' Outranking credibility matrix
#'
#' `outrank_similarity()` aggregates a set of criteria into the ELECTRE-III
#' credibility matrix `S`, the pairwise similarity used for clustering.
#'
#' @details
#' Each criterion contributes a partial concordance `c_j` and discordance
#' `d_j` (see [criterion()]). With weights `w_j` normalised to sum to one, the
#' aggregation is
#' \deqn{C(a, b) = \sum_j w_j\, c_j(a, b),}
#' \deqn{D(a, b) = 1 - \prod_{j \in J(a,b)} \frac{1 - d_j}{1 - c_j},
#'       \quad J(a,b) = \{ j : d_j(a,b) > c_j(a,b) \},}
#' \deqn{S(a, b) = \min\bigl(C(a, b),\, 1 - D(a, b)\bigr).}
#' A criterion with `c_j = 1` is never in `J` (concordance is already maximal),
#' which also avoids the division by `1 - c_j`.
#'
#' Quantile thresholds ([q()]) are resolved against the off-diagonal
#' distribution of each criterion's own measure matrix before the indices are
#' computed. Weights are normalised to sum to one, with a message when they did
#' not already.
#'
#' @param traces A `traces` object (see [as_traces()]); defines the case set
#'   and their order.
#' @param criteria A [criterion()] object, or a non-empty list of them.
#' @param keep_partials If `TRUE`, retain the per-criterion measure,
#'   concordance and discordance matrices for inspection.
#' @return An object of class `outrank_sim`: a list with the credibility
#'   matrix `S`, the aggregate concordance `C` and discordance `D`, the case
#'   ids, the resolved criteria with normalised weights, and (optionally) the
#'   partial matrices.
#' @examples
#' log <- data.frame(
#'   case = rep(c("a", "b", "c"), each = 2),
#'   act  = c("x", "y", "x", "y", "x", "x"),
#'   ts   = as.POSIXct("2020-01-01") + c(0, 1, 0, 1, 0, 1) * 60
#' )
#' tr <- as_traces(log, "case", "act", "ts")
#' # A criterion on a precomputed similarity matrix (crit_* helpers wrap this).
#' m <- matrix(c(1, 0.8, 0.2, 0.8, 1, 0.3, 0.2, 0.3, 1), 3, 3,
#'             dimnames = list(c("a", "b", "c"), c("a", "b", "c")))
#' crit <- criterion(m, direction = "similarity",
#'                   indifference = 0.4, similarity = 0.9, veto = 0.1)
#' outrank_similarity(tr, crit)
#' @export
outrank_similarity <- function(traces, criteria, keep_partials = FALSE) {
  if (inherits(criteria, "criterion")) criteria <- list(criteria)
  if (!is.list(criteria) || !length(criteria) ||
      !all(vapply(criteria, inherits, logical(1L), "criterion"))) {
    stop("`criteria` must be a criterion or a non-empty list of criteria.",
         call. = FALSE)
  }

  ids <- traces$case_ids
  n   <- length(ids)

  weights <- vapply(criteria, function(cr) cr$weight, numeric(1L))
  total   <- sum(weights)
  if (abs(total - 1) > 1e-8) {
    message(sprintf("Criterion weights normalised to sum to 1 (were %g).",
                    total))
  }
  w <- weights / total

  concordance_sum <- matrix(0, n, n, dimnames = list(ids, ids))
  credibility     <- matrix(1, n, n, dimnames = list(ids, ids))
  resolved <- vector("list", length(criteria))
  partials <- if (keep_partials) vector("list", length(criteria)) else NULL

  for (k in seq_along(criteria)) {
    cr <- criteria[[k]]
    v  <- eval_measure(cr$measure, traces, ids)
    cr <- resolve_thresholds(cr, v)
    cr$weight <- w[k]
    resolved[[k]] <- cr

    cc <- partial_concordance(v, cr$indifference, cr$similarity)
    dd <- partial_discordance(v, cr$indifference, cr$veto)

    concordance_sum <- concordance_sum + w[k] * cc
    credibility     <- credibility * credibility_factor(cc, dd)

    if (keep_partials) {
      partials[[k]] <- list(measure = v, concordance = cc, discordance = dd)
    }
  }

  discordance <- 1 - credibility
  s <- pmin(concordance_sum, credibility)  # 1 - discordance == credibility

  structure(
    list(
      S               = s,
      C               = concordance_sum,
      D               = discordance,
      case_ids        = ids,
      criteria        = resolved,
      case_attributes = traces$case_attributes,
      partials        = partials
    ),
    class = "outrank_sim"
  )
}

#' @export
print.outrank_sim <- function(x, ...) {
  s <- x$S
  cat(sprintf("<outrank_sim>: %d cases, %d criteria\n",
              length(x$case_ids), length(x$criteria)))
  cat(sprintf("  S in [%.3f, %.3f], symmetric = %s\n",
              min(s), max(s), isSymmetric(unname(s))))
  if (!is.null(x$partials)) cat("  per-criterion partial indices retained\n")
  invisible(x)
}
