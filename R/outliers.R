# Outlier trimming of the credibility matrix.

## Return an outrank_sim restricted to `keep` (a logical or index/name vector
## over the cases), subsetting every matrix it carries.
subset_sim <- function(sim, keep) {
  ids <- sim$case_ids[keep]
  sim$S <- sim$S[keep, keep, drop = FALSE]
  sim$C <- sim$C[keep, keep, drop = FALSE]
  sim$D <- sim$D[keep, keep, drop = FALSE]
  sim$case_ids <- ids
  if (!is.null(sim$case_attributes)) {
    sim$case_attributes <- sim$case_attributes[keep, , drop = FALSE]
  }
  if (!is.null(sim$partials)) {
    sim$partials <- lapply(sim$partials, function(p) {
      lapply(p, function(m) m[keep, keep, drop = FALSE])
    })
  }
  sim
}

## Row sums of the affinity (diagonal excluded), i.e. each case's total
## similarity to the others.
off_diagonal_rowsums <- function(s) {
  w <- s
  diag(w) <- 0
  rowSums(w)
}

## Integer linear program of Delias et al. (2021): choose k cases to remove so
## that the total similarity on their incident edges is minimal.
lp_outliers <- function(s, k) {
  n <- nrow(s)
  eps <- 1e-6
  obj <- c(rep(0, n), as.vector(s) + eps)  # o-vars then r-vars (column-major)

  ij <- expand.grid(i = seq_len(n), j = seq_len(n))
  i <- ij$i
  j <- ij$j
  p <- seq_len(n * n)                       # r_{i,j} local index (column-major)

  # sum_i o_i = k
  eq <- cbind(1L, seq_len(n), 1)
  # o_i <= r_{i,j}
  rowA <- 1L + p
  a <- rbind(cbind(rowA, i, 1), cbind(rowA, n + p, -1))
  # o_i <= r_{j,i}
  rowB <- 1L + n * n + p
  r_ji <- n + ((i - 1L) * n + j)
  b <- rbind(cbind(rowB, i, 1), cbind(rowB, r_ji, -1))

  dense <- rbind(eq, a, b)
  n_con <- 1L + 2L * n * n
  dir <- c("=", rep("<=", 2L * n * n))
  rhs <- c(k, rep(0, 2L * n * n))

  sol <- lpSolve::lp("min", objective.in = obj,
                     const.dir = dir, const.rhs = rhs,
                     dense.const = dense, all.bin = TRUE)
  if (sol$status != 0L) {
    stop("The outlier-trimming LP did not solve (status ", sol$status, ").",
         call. = FALSE)
  }
  which(sol$solution[seq_len(n)] > 0.5)
}

#' Trim outlier cases
#'
#' `trim_outliers()` removes a fraction of the least-connected cases from an
#' [outrank_similarity()] result, before clustering.
#'
#' @details
#' Let `k = floor(prop * n)`. The `"greedy"` method removes the `k` cases with
#' the smallest total similarity to the others (row sums of `S` with the
#' diagonal excluded). The `"lp"` method solves the integer linear program of
#' Delias et al. (2021),
#' \deqn{\min_{o, r} \sum_{i,j} s_{ij} r_{ij} \quad \text{s.t.} \quad
#'   \sum_i o_i = k,\ o_i \le r_{ij},\ o_i \le r_{ji},\ o, r \in \{0, 1\},}
#' which selects the `k` cases whose incident edges carry the least similarity.
#' A small constant is added to `S` so that zero entries do not leave `r`
#' unconstrained. The LP has `n + n^2` binary variables and is intended for
#' small `n`; it warns above `lp_max`.
#'
#' @param sim An `outrank_sim` object from [outrank_similarity()].
#' @param prop Fraction of cases to remove (in `[0, 1)`).
#' @param method `"greedy"` (default) or `"lp"`.
#' @param lp_max Size above which the `"lp"` method warns about its cost.
#' @return A trimmed `outrank_sim`, with a `trimmed` attribute giving the
#'   removed case ids.
#' @references Delias, P. et al. (2021). Improving the non-compensatory trace
#'   clustering. *International Transactions in Operational Research*.
#' @examples
#' m <- matrix(0.8, 5, 5); m[5, ] <- 0.05; m[, 5] <- 0.05; diag(m) <- 1
#' dimnames(m) <- list(1:5, 1:5)
#' crit <- criterion(m, "similarity", indifference = 0.3, similarity = 0.9)
#' tr <- as_traces(data.frame(case = as.character(1:5), act = "x",
#'                            ts = as.POSIXct("2020-01-01")),
#'                 "case", "act", "ts")
#' sim <- outrank_similarity(tr, crit)
#' trim_outliers(sim, prop = 0.2)
#' @export
trim_outliers <- function(sim, prop = 0.05, method = c("greedy", "lp"),
                          lp_max = 150L) {
  if (!inherits(sim, "outrank_sim")) {
    stop("`sim` must be an outrank_sim object (see outrank_similarity()).",
         call. = FALSE)
  }
  method <- match.arg(method)
  if (!is.numeric(prop) || length(prop) != 1L || is.na(prop) ||
      prop < 0 || prop >= 1) {
    stop("`prop` must be a single number in [0, 1).", call. = FALSE)
  }

  n <- nrow(sim$S)
  k <- floor(prop * n)
  if (k < 1L) {
    message("prop is too small to remove any case; returning `sim` unchanged.")
    keep <- rep(TRUE, n)
    trimmed <- character(0)
  } else {
    if (method == "greedy") {
      rs <- off_diagonal_rowsums(sim$S)
      drop <- which(rank(rs, ties.method = "first") <= k)
    } else {
      if (n > lp_max) {
        warning("The LP method scales as n^2 in the number of variables; ",
                "n = ", n, " may be slow. Consider method = \"greedy\".",
                call. = FALSE)
      }
      drop <- lp_outliers(sim$S, k)
    }
    keep <- !(seq_len(n) %in% drop)
    trimmed <- sim$case_ids[drop]
  }

  out <- subset_sim(sim, keep)
  attr(out, "trimmed") <- trimmed
  out
}
