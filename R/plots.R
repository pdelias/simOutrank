# Diagnostic plots for a clustering.

#' Plot a trace clustering
#'
#' Diagnostic plots for an `outrank_clust` object.
#'
#' @param x An `outrank_clust` object from [cluster_traces()].
#' @param type One of `"dendrogram"` (the hierarchical tree; built on
#'   `as.dist(1 - S)` when the clustering was spectral), `"eigenvalues"` (the
#'   smallest normalized-Laplacian eigenvalues), or `"profile"` (the
#'   distribution of a case `attribute` across clusters).
#' @param attribute For `type = "profile"`, the name of a case attribute
#'   carried by the underlying `sim`.
#' @param ... Passed to the underlying plotting call.
#' @return `x`, invisibly.
#' @examples
#' m <- matrix(0.1, 6, 6); m[1:3, 1:3] <- 0.9; m[4:6, 4:6] <- 0.9
#' diag(m) <- 1; dimnames(m) <- list(1:6, 1:6)
#' crit <- criterion(m, "similarity", indifference = 0.3, similarity = 0.95)
#' tr <- as_traces(data.frame(case = as.character(1:6), act = "x",
#'                            ts = as.POSIXct("2020-01-01")),
#'                 "case", "act", "ts")
#' clust <- cluster_traces(outrank_similarity(tr, crit), k = 2, seed = 1)
#' plot(clust, type = "eigenvalues")
#' @export
plot.outrank_clust <- function(x, type = c("dendrogram", "eigenvalues",
                                           "profile"),
                               attribute = NULL, ...) {
  type <- match.arg(type)
  s <- x$sim$S

  if (type == "dendrogram") {
    tree <- x$hclust
    if (is.null(tree)) {
      tree <- stats::hclust(stats::as.dist(1 - s), method = "ward.D2")
    }
    graphics::plot(tree, main = "Trace dendrogram", xlab = "", sub = "", ...)

  } else if (type == "eigenvalues") {
    vals <- x$eigenvalues
    if (is.null(vals)) vals <- laplacian_eigen(s)$values
    graphics::plot(seq_along(vals), vals, type = "b", pch = 19,
                   xlab = "Index", ylab = "Eigenvalue",
                   main = "Normalized Laplacian eigenvalues", ...)

  } else {
    attrs <- x$sim$case_attributes
    if (is.null(attribute) || is.null(attrs) || !(attribute %in% names(attrs))) {
      stop("`type = \"profile\"` needs `attribute` to name a case attribute ",
           "carried by the sim.", call. = FALSE)
    }
    tab <- table(attrs[[attribute]], x$memberships)
    prop <- prop.table(tab, margin = 2L)
    graphics::barplot(prop, legend.text = rownames(prop),
                      xlab = "Cluster", ylab = "Proportion",
                      main = paste0("Distribution of '", attribute,
                                    "' by cluster"),
                      ...)
  }
  invisible(x)
}
