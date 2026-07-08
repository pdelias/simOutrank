# A minimal outrank_sim wrapper around a bare similarity matrix.
make_sim <- function(s) {
  structure(
    list(S = s, C = s, D = 1 - s, case_ids = rownames(s),
         criteria = list(), partials = NULL),
    class = "outrank_sim"
  )
}

# Two well-separated blocks {1,2,3} and {4,5,6}.
block_sim <- function() {
  s <- matrix(0.1, 6, 6)
  s[1:3, 1:3] <- 0.9
  s[4:6, 4:6] <- 0.9
  diag(s) <- 1
  dimnames(s) <- list(as.character(1:6), as.character(1:6))
  make_sim(s)
}

test_that("spectral clustering recovers separated blocks", {
  cl <- cluster_traces(block_sim(), k = 2, seed = 1)
  m <- cl$memberships

  expect_s3_class(cl, "outrank_clust")
  expect_equal(cl$method, "spectral")
  expect_named(m, as.character(1:6))
  expect_length(unique(m), 2L)
  # Within-block agreement, across-block disagreement (up to label switching).
  expect_true(m[["1"]] == m[["2"]] && m[["2"]] == m[["3"]])
  expect_true(m[["4"]] == m[["5"]] && m[["5"]] == m[["6"]])
  expect_true(m[["1"]] != m[["4"]])
  expect_length(cl$eigenvalues, 6L)
})

test_that("hierarchical clustering recovers separated blocks", {
  cl <- cluster_traces(block_sim(), k = 2, method = "hierarchical")
  m <- cl$memberships

  expect_equal(cl$method, "hierarchical")
  expect_s3_class(cl$hclust, "hclust")
  expect_true(m[["1"]] == m[["2"]] && m[["2"]] == m[["3"]])
  expect_true(m[["4"]] == m[["5"]] && m[["5"]] == m[["6"]])
  expect_true(m[["1"]] != m[["4"]])
})

test_that("the spectral seed is reproducible and RNG state is restored", {
  set.seed(99)
  before <- .Random.seed
  a <- cluster_traces(block_sim(), k = 2, seed = 7)$memberships
  b <- cluster_traces(block_sim(), k = 2, seed = 7)$memberships
  expect_identical(a, b)
  # The function must not leave the global RNG perturbed.
  expect_identical(.Random.seed, before)
})

test_that("eigengap places the largest gap at the true k", {
  grDevices::pdf(tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off())
  eg <- eigengap(block_sim(), k_max = 6)

  expect_s3_class(eg, "data.frame")
  expect_equal(nrow(eg), 6L)
  # Two near-zero eigenvalues, then a jump -> largest gap after index 2.
  gaps <- eg$gap[!is.na(eg$gap)]
  expect_equal(which.max(gaps), 2L)
})

test_that("cluster_traces validates its inputs", {
  expect_error(cluster_traces(list(), k = 2), "outrank_sim")
  expect_error(cluster_traces(block_sim(), k = 1), "\\[2,")
  expect_error(cluster_traces(block_sim(), k = 7), "\\[2,")
  expect_error(cluster_traces(block_sim(), k = 2.5), "integer")
})
