test_that("as_quantile() validates its probability", {
  expect_s3_class(as_quantile(0.5), "outrank_quantile")
  expect_equal(as_quantile(0.8)$p, 0.8)
  expect_error(as_quantile(-0.1), "\\[0, 1\\]")
  expect_error(as_quantile(2), "\\[0, 1\\]")
  expect_error(as_quantile(c(0.2, 0.3)), "single")
})

test_that("similarity-direction ordering is validated", {
  m <- matrix(0, 2, 2)
  expect_s3_class(
    criterion(m, "similarity", indifference = 0.5, similarity = 0.8,
              veto = 0.2),
    "criterion"
  )
  # indifference must be below similarity.
  expect_error(
    criterion(m, "similarity", indifference = 0.8, similarity = 0.6),
    "indifference < similarity"
  )
  # veto must be below indifference.
  expect_error(
    criterion(m, "similarity", indifference = 0.6, similarity = 0.8,
              veto = 0.7),
    "veto < indifference"
  )
})

test_that("dissimilarity-direction ordering is validated (reversed)", {
  m <- matrix(0, 2, 2)
  expect_s3_class(
    criterion(m, "dissimilarity", indifference = 0.8, similarity = 0.6,
              veto = 1.0),
    "criterion"
  )
  expect_error(
    criterion(m, "dissimilarity", indifference = 0.6, similarity = 0.8),
    "similarity < indifference"
  )
  expect_error(
    criterion(m, "dissimilarity", indifference = 0.8, similarity = 0.6,
              veto = 0.5),
    "indifference < veto"
  )
})

test_that("bad measure, weight and thresholds are rejected", {
  m <- matrix(0, 2, 2)
  expect_error(criterion("nope", "similarity",
                         indifference = 0.5, similarity = 0.8), "function")
  expect_error(criterion(m, "similarity", weight = -1,
                         indifference = 0.5, similarity = 0.8), "positive")
  expect_error(criterion(m, "similarity", similarity = 0.8), "required")
})

test_that("quantile thresholds are resolved on the off-diagonal distribution", {
  # Symmetric matrix with off-diagonal values 2, 4, 6.
  mat <- matrix(0, 3, 3)
  mat[upper.tri(mat)] <- c(2, 4, 6)
  mat[lower.tri(mat)] <- t(mat)[lower.tri(mat)]

  crit <- criterion(mat, "dissimilarity",
                    indifference = as_quantile(0.5), similarity = as_quantile(0.25), veto = as_quantile(0.9))
  resolved <- resolve_thresholds(crit, mat)

  expect_equal(resolved$indifference, stats::quantile(c(2, 4, 6), 0.5,
                                                      names = FALSE))
  expect_equal(resolved$similarity, stats::quantile(c(2, 4, 6), 0.25,
                                                    names = FALSE))
  expect_equal(resolved$veto, stats::quantile(c(2, 4, 6), 0.9, names = FALSE))
  # median 4 is a plain number now, not a quantile spec.
  expect_false(is_quantile(resolved$indifference))
})

test_that("quantile resolution enforces ordering after resolution", {
  mat <- matrix(0, 3, 3)
  mat[upper.tri(mat)] <- c(2, 4, 6)
  mat[lower.tri(mat)] <- t(mat)[lower.tri(mat)]

  # Similarity direction but indifference quantile lands above similarity.
  crit <- criterion(mat, "similarity",
                    indifference = as_quantile(0.9), similarity = as_quantile(0.1))
  expect_error(resolve_thresholds(crit, mat), "indifference < similarity")
})
