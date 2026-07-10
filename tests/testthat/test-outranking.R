# --- Partial indices ---------------------------------------------------------

test_that("similarity-direction partial indices match hand values", {
  # indifference q = 0.2, similarity s = 0.6, veto t = 0.1.
  v <- matrix(c(0.05, 0.10, 0.15, 0.20, 0.40, 0.60, 0.80), nrow = 1)

  cc <- partial_concordance(v, indifference = 0.2, similarity = 0.6)
  # below q -> 0; at q -> 0; midway (0.4) -> 0.5; at s -> 1; above -> 1.
  expect_equal(as.numeric(cc), c(0, 0, 0, 0, 0.5, 1, 1))

  dd <- partial_discordance(v, indifference = 0.2, veto = 0.1)
  # below t -> 1; at t -> 1; midway (0.15) -> 0.5; at q -> 0; above q -> 0.
  expect_equal(as.numeric(dd), c(1, 1, 0.5, 0, 0, 0, 0))
})

test_that("dissimilarity-direction partial indices match hand values", {
  # similarity s = 2, indifference q = 3, veto t = 6  (s < q < t).
  v <- matrix(c(1, 2, 2.5, 3, 4.5, 6, 7), nrow = 1)

  cc <- partial_concordance(v, indifference = 3, similarity = 2)
  expect_equal(as.numeric(cc), c(1, 1, 0.5, 0, 0, 0, 0))

  dd <- partial_discordance(v, indifference = 3, veto = 6)
  expect_equal(as.numeric(dd), c(0, 0, 0, 0, 0.5, 1, 1))
})

test_that("a NULL veto contributes no discordance", {
  v <- matrix(c(0, 0.5, 0.5, 0), 2, 2)
  dd <- partial_discordance(v, indifference = 0.2, veto = NULL)
  expect_equal(dd, matrix(0, 2, 2))
})

# --- Aggregation on a 3-case hand-computed example ---------------------------

# Two similarity criteria on cases 1, 2, 3, thresholds chosen so that the
# example exercises the J-set exclusion (d <= c) and the c = 1 guard.
#
# Criterion A: q = 0.2, s = 0.6, t = 0.1
# Criterion B: q = 0.5, s = 0.9, t = 0.3
#
# Pair (1,2): A -> c 0.5, d 0 (not in J); B -> c 0, d 0.75 (in J)
#   C = 0.25, 1-D = (1-0.75)/(1-0) = 0.25, S = 0.25
# Pair (1,3): A -> c 1 (guard), B -> c 1 (guard); J empty; C = 1, S = 1
# Pair (2,3): A -> c 0, d 1 (veto, in J, factor 0); B -> c 0, d 0 (not in J)
#   1-D = 0, S = 0
hand_criteria <- function() {
  va <- matrix(c(1, 0.40, 0.70,
                 0.40, 1, 0.05,
                 0.70, 0.05, 1), 3, 3,
               dimnames = list(1:3, 1:3))
  vb <- matrix(c(1, 0.35, 0.95,
                 0.35, 1, 0.50,
                 0.95, 0.50, 1), 3, 3,
               dimnames = list(1:3, 1:3))
  list(
    criterion(va, "similarity", weight = 1,
              indifference = 0.2, similarity = 0.6, veto = 0.1, name = "A"),
    criterion(vb, "similarity", weight = 1,
              indifference = 0.5, similarity = 0.9, veto = 0.3, name = "B")
  )
}

hand_traces <- function() {
  as_traces(
    data.frame(case = as.character(1:3), act = "x",
               ts = as.POSIXct("2020-01-01", tz = "UTC")),
    "case", "act", "ts"
  )
}

test_that("aggregation reproduces the hand-computed credibility matrix", {
  expected <- matrix(c(1, 0.25, 1,
                       0.25, 1, 0,
                       1, 0, 1), 3, 3,
                     dimnames = list(as.character(1:3), as.character(1:3)))

  sim <- suppressMessages(outrank_similarity(hand_traces(), hand_criteria()))
  expect_equal(sim$S, expected)
})

test_that("the c = 1 guard produces no NaN or Inf", {
  sim <- suppressMessages(outrank_similarity(hand_traces(), hand_criteria()))
  expect_false(any(is.nan(sim$S)) || any(is.infinite(sim$S)))
  expect_false(any(is.nan(sim$D)) || any(is.infinite(sim$D)))
})

test_that("weights are normalised with a message", {
  expect_message(
    outrank_similarity(hand_traces(), hand_criteria()),
    "normalised"
  )
  sim <- suppressMessages(outrank_similarity(hand_traces(), hand_criteria()))
  expect_equal(vapply(sim$criteria, function(cr) cr$weight, numeric(1)),
               c(0.5, 0.5))
})

# --- Invariants of S on real traces/measures ---------------------------------

test_that("S is symmetric, named and in [0, 1] on real measures", {
  tr <- toy_traces()
  criteria <- list(
    criterion(function(t) measure_activity_profile(t), "similarity",
              weight = 2, indifference = 0.3, similarity = 0.8, veto = 0.1),
    criterion(function(t) measure_edit_distance(t), "dissimilarity",
              weight = 1, indifference = as_quantile(0.25), similarity = 0, veto = as_quantile(0.75))
  )
  sim <- suppressMessages(outrank_similarity(tr, criteria, keep_partials = TRUE))

  expect_equal(dimnames(sim$S), list(c("A", "B", "C"), c("A", "B", "C")))
  expect_equal(sim$S, t(sim$S))
  expect_true(all(sim$S >= 0 & sim$S <= 1))
  expect_length(sim$partials, 2)
  expect_named(sim$partials[[1]], c("measure", "concordance", "discordance"))
})

test_that("criteria input is validated", {
  expect_error(outrank_similarity(hand_traces(), list()), "non-empty")
  expect_error(outrank_similarity(hand_traces(), "nope"), "criterion")
})
