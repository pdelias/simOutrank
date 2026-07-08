# Expected values are hand-computed for the toy log (see helper-toy.R):
#   A = X Y Z, B = X Y Z (identical), C = X X.

test_that("measures return symmetric, named matrices", {
  tr <- toy_traces()
  ids <- c("A", "B", "C")
  for (m in list(
    measure_activity_profile(tr),
    measure_transitions(tr),
    measure_edit_distance(tr),
    measure_trace_length(tr),
    measure_distinct_activities(tr),
    measure_duration(tr)
  )) {
    expect_equal(dim(m), c(3L, 3L))
    expect_equal(dimnames(m), list(ids, ids))
    expect_equal(m, t(m))
  }
})

test_that("activity-profile cosine matches by hand", {
  m <- measure_activity_profile(toy_traces())
  # Identical count vectors -> cosine 1.
  expect_equal(m["A", "B"], 1)
  expect_equal(diag(m), c(A = 1, B = 1, C = 1))
  # A = (1,1,1), C = (2,0,0): dot 2, norms sqrt(3) and 2 -> 1/sqrt(3).
  expect_equal(m["A", "C"], 1 / sqrt(3))
  expect_true(all(m >= 0 & m <= 1 + 1e-12))
})

test_that("transition-profile cosine matches by hand", {
  m <- measure_transitions(toy_traces())
  # A and B share the same transitions -> cosine 1.
  expect_equal(m["A", "B"], 1)
  # A's transitions (X->Y, X->Z, Y->Z) share nothing with C's (X->X) -> 0.
  expect_equal(m["A", "C"], 0)
})

test_that("edit distance is OSA on integer sequences", {
  m <- measure_edit_distance(toy_traces())
  expect_equal(diag(m), c(A = 0, B = 0, C = 0))
  expect_equal(m["A", "B"], 0)   # identical
  expect_equal(m["A", "C"], 2)   # XYZ -> XX: substitute + delete
})

test_that("length and distinct-activity dissimilarities match by hand", {
  len <- measure_trace_length(toy_traces())
  expect_equal(len["A", "B"], 0)
  expect_equal(len["A", "C"], 1)   # 3 vs 2 events

  dst <- measure_distinct_activities(toy_traces())
  expect_equal(dst["A", "B"], 0)
  expect_equal(dst["A", "C"], 2)   # 3 vs 1 distinct activities
})

test_that("duration dissimilarity uses the requested units", {
  m <- measure_duration(toy_traces(), units = "mins")
  # A, B span 2 min; C spans 10 min.
  expect_equal(m["A", "B"], 0)
  expect_equal(m["A", "C"], 8)
  expect_equal(diag(m), c(A = 0, B = 0, C = 0))
})
