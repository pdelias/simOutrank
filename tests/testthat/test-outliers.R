test_that("greedy trimming removes the least-connected cases", {
  sim <- outlier_sim()
  out <- trim_outliers(sim, prop = 0.2, method = "greedy")

  expect_equal(attr(out, "trimmed"), "5")
  expect_equal(out$case_ids, as.character(1:4))
  expect_equal(dim(out$S), c(4L, 4L))
  expect_false("5" %in% rownames(out$S))
})

test_that("the LP method selects the same obvious outlier", {
  sim <- outlier_sim()
  out <- trim_outliers(sim, prop = 0.2, method = "lp")
  expect_equal(attr(out, "trimmed"), "5")
  expect_equal(dim(out$S), c(4L, 4L))
})

test_that("k scales with prop and n", {
  sim <- outlier_sim()  # n = 5
  expect_length(attr(trim_outliers(sim, prop = 0.4), "trimmed"), 2L)  # floor(2.0)
  expect_equal(dim(trim_outliers(sim, prop = 0.4)$S), c(3L, 3L))
})

test_that("too-small prop leaves the sim unchanged with a message", {
  sim <- outlier_sim()
  expect_message(out <- trim_outliers(sim, prop = 0.1), "unchanged")  # floor(0.5)=0
  expect_equal(out$case_ids, sim$case_ids)
  expect_length(attr(out, "trimmed"), 0L)
})

test_that("trim_outliers validates inputs", {
  expect_error(trim_outliers(list(), prop = 0.1), "outrank_sim")
  expect_error(trim_outliers(outlier_sim(), prop = 1), "\\[0, 1\\)")
  expect_error(trim_outliers(outlier_sim(), prop = -0.1), "\\[0, 1\\)")
})
