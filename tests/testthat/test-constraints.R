test_that("must_link rewards pairs and caps at 1", {
  sim <- attr_sim()  # off-diagonal S = 0.5

  # Small reward: no cap.
  ml <- must_link(sim, cbind("a", "c"), reward = 0.3)
  expect_equal(ml$S["a", "c"], 0.8)
  expect_equal(ml$S["c", "a"], 0.8)          # symmetric
  expect_equal(ml$S["a", "b"], 0.5)          # untouched pair

  # Large reward: capped at 1.
  ml2 <- must_link(sim, cbind("a", "c"), reward = 2)
  expect_equal(ml2$S["a", "c"], 1)
})

test_that("cannot_link severs pairs", {
  sim <- attr_sim()
  cl <- cannot_link(sim, cbind("a", "b"))
  expect_equal(cl$S["a", "b"], 0)
  expect_equal(cl$S["b", "a"], 0)
  expect_equal(cl$S["a", "c"], 0.5)          # untouched pair
})

test_that("attribute-based must_link links equal values", {
  sim <- attr_sim()  # grp: a,b = G ; c,d = B
  ml <- must_link(sim, "grp", reward = 0.3)
  expect_equal(ml$S["a", "b"], 0.8)          # same group -> rewarded
  expect_equal(ml$S["c", "d"], 0.8)
  expect_equal(ml$S["a", "c"], 0.5)          # different group -> untouched
  expect_equal(diag(ml$S), c(a = 1, b = 1, c = 1, d = 1))  # diagonal untouched
})

test_that("attribute-based cannot_link severs differing values", {
  sim <- attr_sim()
  cl <- cannot_link(sim, "grp")
  expect_equal(cl$S["a", "c"], 0)            # G vs B -> severed
  expect_equal(cl$S["b", "d"], 0)
  expect_equal(cl$S["a", "b"], 0.5)          # same group -> kept
})

test_that("constraint inputs are validated", {
  sim <- attr_sim()
  expect_error(must_link(sim, cbind("a", "z")), "unknown case ids")
  expect_error(must_link(sim, "nope"), "not found")
  expect_error(must_link(sim, cbind("a", 0.5), reward = -1), "positive")
  expect_error(cannot_link(sim, matrix(1:6, ncol = 3)), "two-column")
})
