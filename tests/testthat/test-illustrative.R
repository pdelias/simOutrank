# Regression test on the illustrative log of Delias et al. (2023).
#
# The paper's per-case memberships (Table 3) are published as a shape figure
# and are not machine-readable; our spectral step also uses the corrected
# NJW row-normalisation (design section 2) rather than the column
# normalisation of the original scripts, so a bit-for-bit membership match is
# not expected. Following the design's fallback, we pin the deterministic
# credibility matrix S and assert reproducibility and paper-independent
# structural invariants.

test_that("illustrative pipeline reproduces the pinned credibility matrix", {
  sim <- illustrative_sim()
  expected <- readRDS(test_path("fixtures", "illustrative_S.rds"))

  expect_equal(dim(sim$S), c(25L, 25L))
  expect_equal(sim$S, expected)
})

test_that("S satisfies its invariants on the illustrative log", {
  s <- illustrative_sim()$S

  expect_equal(nrow(s), 25L)
  expect_equal(s, t(s))
  expect_true(all(s >= 0 & s <= 1))
  # Cases with an identical (trace, status, satisfaction) profile are fully
  # similar under every criterion (case ids 1-25 follow Table 1's order).
  expect_equal(s["1", "2"], 1)      # Gold short path (B, E)
  expect_equal(s["11", "15"], 1)    # Normal short path (A, C, D, E)
  expect_equal(s["9", "10"], 1)     # Gold, low satisfaction
  expect_equal(s["16", "21"], 1)    # Normal long path
})

test_that("spectral clustering is reproducible and yields four groups", {
  sim <- illustrative_sim()
  a <- cluster_traces(sim, k = 4, seed = 42)$memberships
  b <- cluster_traces(sim, k = 4, seed = 42)$memberships

  expect_identical(a, b)
  expect_length(unique(a), 4L)
  expect_true(all(table(a) > 0))
})

test_that("cases with identical profiles share a cluster", {
  m <- cluster_traces(illustrative_sim(), k = 4, seed = 42)$memberships
  identical_groups <- list(
    as.character(1:5), as.character(6:8), as.character(9:10),
    as.character(11:15), as.character(16:21), as.character(22:23)
  )
  for (g in identical_groups) {
    expect_length(unique(m[g]), 1L)
  }
})
