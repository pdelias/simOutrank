# Clustering and spectral diagnostics on the credibility matrix S.

## Symmetric normalized Laplacian eigen-decomposition of an affinity matrix.
##
## The affinity is S with a zeroed diagonal (no self-loops, as in
## Ng-Jordan-Weiss). With D = diag(rowSums(W)),
##   L_sym = I - D^{-1/2} W D^{-1/2}.
## Returns eigenvalues and eigenvectors in ascending eigenvalue order, so the
## first columns/values correspond to the smallest eigenvalues used for the
## embedding.
laplacian_eigen <- function(s) {
  w <- s
  diag(w) <- 0
  d <- rowSums(w)
  if (any(d <= 0)) {
    stop("Cannot form the normalized Laplacian: some cases have zero total ",
         "similarity to all others.", call. = FALSE)
  }
  dm <- 1 / sqrt(d)
  l_sym <- diag(nrow(w)) - outer(dm, dm) * w
  e <- eigen(l_sym, symmetric = TRUE)
  ord <- order(e$values)  # ascending
  list(values = e$values[ord], vectors = e$vectors[, ord, drop = FALSE])
}

## Ng-Jordan-Weiss spectral embedding: the k smallest-eigenvalue eigenvectors
## of L_sym, with each row scaled to unit norm.
spectral_embedding <- function(s, k) {
  le <- laplacian_eigen(s)
  u <- le$vectors[, seq_len(k), drop = FALSE]
  rn <- sqrt(rowSums(u * u))
  rn[rn == 0] <- 1
  list(embedding = u / rn, eigenvalues = le$values)
}

#' Cluster traces from a credibility matrix
#'
#' `cluster_traces()` partitions the cases of an [outrank_similarity()] result
#' into `k` groups, by normalized spectral clustering or hierarchical
#' clustering.
#'
#' @details
#' Spectral clustering follows Ng, Jordan and Weiss (2002). With the affinity
#' `S` (diagonal zeroed) and `D = diag(rowSums(S))`, it forms the symmetric
#' normalized Laplacian \eqn{L_{sym} = I - D^{-1/2} S D^{-1/2}}, takes the
#' eigenvectors of its `k` smallest eigenvalues, normalises each row to unit
#' length, and runs k-means (with `nstart` restarts) on the result.
#'
#' Hierarchical clustering runs [stats::hclust()] on the dissimilarity
#' `as.dist(1 - S)` and cuts the tree at `k` groups.
#'
#' @param sim An `outrank_sim` object from [outrank_similarity()].
#' @param k Number of clusters (an integer, `2 <= k <= n`).
#' @param method `"spectral"` (default) or `"hierarchical"`.
#' @param nstart Number of k-means restarts for the spectral method.
#' @param seed Optional integer seed for the k-means randomness; set it for
#'   reproducible spectral memberships. The global RNG state is restored on
#'   exit.
#' @param hclust_method Linkage for the hierarchical method; passed to
#'   [stats::hclust()]. Defaults to `"ward.D2"`.
#' @return An object of class `outrank_clust`: a list with the integer
#'   `memberships` (named by case id), `k`, `method`, the `sim` object, the
#'   Laplacian `eigenvalues` (spectral only), and the `hclust` tree
#'   (hierarchical only).
#' @references Ng, A., Jordan, M. and Weiss, Y. (2002). On spectral clustering:
#'   analysis and an algorithm. *NIPS*.
#' @examples
#' m <- matrix(c(1, 0.9, 0.1, 0.1,
#'               0.9, 1, 0.1, 0.1,
#'               0.1, 0.1, 1, 0.9,
#'               0.1, 0.1, 0.9, 1), 4, 4,
#'             dimnames = list(1:4, 1:4))
#' crit <- criterion(m, "similarity", indifference = 0.3, similarity = 0.95)
#' tr <- as_traces(
#'   data.frame(case = as.character(1:4), act = "x",
#'              ts = as.POSIXct("2020-01-01")),
#'   "case", "act", "ts"
#' )
#' sim <- outrank_similarity(tr, crit)
#' cluster_traces(sim, k = 2, seed = 1)
#' @export
cluster_traces <- function(sim, k, method = c("spectral", "hierarchical"),
                           nstart = 100, seed = NULL,
                           hclust_method = "ward.D2") {
  if (!inherits(sim, "outrank_sim")) {
    stop("`sim` must be an outrank_sim object (see outrank_similarity()).",
         call. = FALSE)
  }
  method <- match.arg(method)
  s <- sim$S
  n <- nrow(s)
  if (!is.numeric(k) || length(k) != 1L || k != as.integer(k) ||
      k < 2L || k > n) {
    stop(sprintf("`k` must be a single integer in [2, %d].", n), call. = FALSE)
  }
  k <- as.integer(k)

  eigenvalues <- NULL
  tree <- NULL

  if (method == "spectral") {
    emb <- spectral_embedding(s, k)
    eigenvalues <- emb$eigenvalues
    if (!is.null(seed)) {
      if (exists(".Random.seed", envir = globalenv())) {
        old_seed <- get(".Random.seed", envir = globalenv())
        on.exit(assign(".Random.seed", old_seed, envir = globalenv()),
                add = TRUE)
      }
      set.seed(seed)
    }
    km <- stats::kmeans(emb$embedding, centers = k, nstart = nstart)
    memberships <- km$cluster
  } else {
    tree <- stats::hclust(stats::as.dist(1 - s), method = hclust_method)
    memberships <- stats::cutree(tree, k = k)
  }

  memberships <- as.integer(memberships)
  names(memberships) <- rownames(s)

  structure(
    list(
      memberships   = memberships,
      k             = k,
      method        = method,
      sim           = sim,
      eigenvalues   = eigenvalues,
      hclust        = tree,
      nstart        = if (method == "spectral") nstart else NULL,
      seed          = seed,
      hclust_method = if (method == "hierarchical") hclust_method else NULL
    ),
    class = "outrank_clust"
  )
}

#' @export
print.outrank_clust <- function(x, ...) {
  sizes <- table(x$memberships)
  cat(sprintf("<outrank_clust>: %d cases in %d clusters (%s)\n",
              length(x$memberships), x$k, x$method))
  cat("  cluster sizes:",
      paste(sprintf("%s=%d", names(sizes), as.integer(sizes)),
            collapse = ", "), "\n")
  invisible(x)
}

#' Eigenvalue gap diagnostic
#'
#' `eigengap()` plots the smallest eigenvalues of the symmetric normalized
#' Laplacian of `S`. A pronounced gap after the `k`-th eigenvalue suggests `k`
#' well-separated clusters.
#'
#' @param sim An `outrank_sim` object from [outrank_similarity()].
#' @param k_max Number of smallest eigenvalues to show.
#' @return Invisibly, a data frame with the eigenvalue `index`, the
#'   `eigenvalue`, and the `gap` to the next one.
#' @examples
#' m <- matrix(0.1, 6, 6) + diag(0.9, 6)
#' m[1:3, 1:3] <- 0.9; m[4:6, 4:6] <- 0.9; diag(m) <- 1
#' dimnames(m) <- list(1:6, 1:6)
#' crit <- criterion(m, "similarity", indifference = 0.3, similarity = 0.95)
#' tr <- as_traces(
#'   data.frame(case = as.character(1:6), act = "x",
#'              ts = as.POSIXct("2020-01-01")),
#'   "case", "act", "ts"
#' )
#' eigengap(outrank_similarity(tr, crit), k_max = 5)
#' @export
eigengap <- function(sim, k_max = 30) {
  if (!inherits(sim, "outrank_sim")) {
    stop("`sim` must be an outrank_sim object (see outrank_similarity()).",
         call. = FALSE)
  }
  vals <- laplacian_eigen(sim$S)$values
  m <- min(k_max, length(vals))
  idx <- seq_len(m)
  vals <- vals[idx]
  graphics::plot(idx, vals, type = "b", pch = 19,
                 xlab = "Index", ylab = "Eigenvalue",
                 main = "Normalized Laplacian eigenvalues")
  invisible(data.frame(index = idx, eigenvalue = vals,
                       gap = c(diff(vals), NA_real_)))
}
