# Regression tests on the BPIC'11 credibility matrix of Delias et al. (2023),
# Section 4.2-4.3. The fixture is local-only, so these skip on CRAN and when it
# is absent (see helper-bpic.R).

test_that("BPIC spectral clustering reproduces the k=4 solution", {
  skip_if_no_bpic()
  sim <- load_bpic_sim()

  cl <- cluster_traces(sim, k = 4, seed = 1000, nstart = 100)
  expect_length(cl$memberships, 1500L)
  expect_equal(sort(as.integer(table(cl$memberships))),
               c(250L, 292L, 465L, 493L))

  cl2 <- cluster_traces(sim, k = 4, seed = 1000, nstart = 100)
  expect_identical(cl$memberships, cl2$memberships)
})

test_that("trimming and constraints scale to the BPIC matrix", {
  skip_if_no_bpic()
  sim <- load_bpic_sim()

  trimmed <- trim_outliers(sim, prop = 0.05)      # floor(0.05 * 1500) = 75
  expect_equal(nrow(trimmed$S), 1425L)
  expect_length(attr(trimmed, "trimmed"), 75L)

  expect_equal(cannot_link(sim, cbind("1", "2"))$S["1", "2"], 0)
  expect_equal(must_link(sim, cbind("1", "2"), reward = 2)$S["1", "2"], 1)
})
