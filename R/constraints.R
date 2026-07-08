# Pairwise must-link / cannot-link adjustments to the credibility matrix.

## Build a symmetric 0/1 constraint mask (zero diagonal) from either a
## two-column matrix of case-id pairs or the name of a case attribute. For an
## attribute, `relation` selects equal-valued ("equal") or differing-valued
## ("unequal") pairs.
constraint_mask <- function(sim, spec, relation) {
  ids <- sim$case_ids
  n <- length(ids)
  m <- matrix(0, n, n, dimnames = list(ids, ids))

  if (is.character(spec) && length(spec) == 1L) {
    attrs <- sim$case_attributes
    if (is.null(attrs) || !(spec %in% names(attrs))) {
      stop("Attribute '", spec, "' not found on the sim's cases. Store case ",
           "attributes by building `sim` from a traces object, or pass a ",
           "matrix of case-id pairs instead.", call. = FALSE)
    }
    v <- attrs[[spec]]
    equal <- outer(v, v, "==")
    m[] <- if (relation == "equal") equal else !equal
  } else {
    pairs <- as.matrix(spec)
    if (ncol(pairs) != 2L) {
      stop("`pairs_or_attribute` must be a two-column matrix of case-id pairs ",
           "or a single attribute name.", call. = FALSE)
    }
    a <- match(as.character(pairs[, 1L]), ids)
    b <- match(as.character(pairs[, 2L]), ids)
    if (anyNA(a) || anyNA(b)) {
      stop("`pairs_or_attribute` refers to unknown case ids.", call. = FALSE)
    }
    m[cbind(c(a, b), c(b, a))] <- 1
  }
  diag(m) <- 0
  m
}

#' Must-link and cannot-link constraints
#'
#' Inject domain knowledge into the credibility matrix by rewarding pairs that
#' should share a cluster (`must_link()`) or severing pairs that should not
#' (`cannot_link()`), following Delias et al. (2021).
#'
#' @details
#' With a symmetric 0/1 constraint mask `M` (zero diagonal),
#' \deqn{\text{must\_link:}\quad S \leftarrow \min(S + \text{reward}\cdot M,\ 1),}
#' \deqn{\text{cannot\_link:}\quad S \leftarrow S \odot (1 - M).}
#' The constraint set is given either as a two-column matrix of case-id pairs,
#' or as the name of a case attribute: `must_link()` then links cases with an
#' equal attribute value, and `cannot_link()` severs cases whose values differ.
#'
#' @param sim An `outrank_sim` object from [outrank_similarity()].
#' @param pairs_or_attribute A two-column matrix of case-id pairs, or a
#'   length-one attribute name (requires that `sim` carries case attributes).
#' @param reward Positive amount added to `S` for each must-linked pair.
#' @return The `outrank_sim` with an updated `S`.
#' @name constraints
#' @examples
#' m <- matrix(0.2, 4, 4); diag(m) <- 1; dimnames(m) <- list(1:4, 1:4)
#' crit <- criterion(m, "similarity", indifference = 0.1, similarity = 0.9)
#' tr <- as_traces(data.frame(case = as.character(1:4), act = "x",
#'                            ts = as.POSIXct("2020-01-01")),
#'                 "case", "act", "ts")
#' sim <- outrank_similarity(tr, crit)
#' sim <- must_link(sim, cbind("1", "2"))
#' cannot_link(sim, cbind("3", "4"))$S
NULL

#' @rdname constraints
#' @export
must_link <- function(sim, pairs_or_attribute, reward = 2) {
  if (!inherits(sim, "outrank_sim")) {
    stop("`sim` must be an outrank_sim object.", call. = FALSE)
  }
  if (!is.numeric(reward) || length(reward) != 1L || is.na(reward) ||
      reward <= 0) {
    stop("`reward` must be a single positive number.", call. = FALSE)
  }
  m <- constraint_mask(sim, pairs_or_attribute, relation = "equal")
  sim$S <- pmin(sim$S + reward * m, 1)
  sim
}

#' @rdname constraints
#' @export
cannot_link <- function(sim, pairs_or_attribute) {
  if (!inherits(sim, "outrank_sim")) {
    stop("`sim` must be an outrank_sim object.", call. = FALSE)
  }
  m <- constraint_mask(sim, pairs_or_attribute, relation = "unequal")
  sim$S <- sim$S * (1 - m)
  sim
}
