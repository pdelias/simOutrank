test_that("process helpers build criteria with the right direction", {
  expect_s3_class(crit_activity_profile(0.2), "criterion")
  expect_equal(crit_activity_profile(0.2)$direction, "similarity")
  expect_equal(crit_transitions(0.2)$direction, "similarity")
  expect_equal(crit_edit_distance(0.2)$direction, "dissimilarity")
  expect_equal(crit_trace_length()$direction, "dissimilarity")
  expect_equal(crit_distinct_activities()$direction, "dissimilarity")
  expect_equal(crit_duration()$direction, "dissimilarity")
  expect_equal(crit_activity_profile(0.2)$name, "activity_profile")
})

test_that("a process-helper criterion matches its underlying measure", {
  tr <- toy_traces()
  crit <- crit_activity_profile(weight = 1, indifference = 0.3,
                                similarity = 0.8)
  sim <- suppressMessages(outrank_similarity(tr, crit))
  # With one similarity criterion, veto NULL, S == the concordance of the
  # measure; check it is consistent with the measure's ordering.
  expect_equal(dimnames(sim$S), list(c("A", "B", "C"), c("A", "B", "C")))
  expect_equal(sim$S["A", "B"], 1)          # identical traces
  expect_true(sim$S["A", "C"] < 1)
})

test_that("crit_edit_distance overrides carry through", {
  crit <- crit_edit_distance(weight = 0.2, similarity = 2, indifference = 3,
                             veto = 6)
  expect_equal(crit$similarity, 2)
  expect_equal(crit$indifference, 3)
  expect_equal(crit$veto, 6)
})

test_that("crit_nominal scores equality from a case attribute", {
  sim <- suppressMessages(outrank_similarity(
    as_traces(illustrative_log, "case_id", "activity", "timestamp"),
    crit_nominal("status", weight = 1)
  ))
  # Same status -> 1, different status -> 0.
  expect_equal(sim$S["G1", "G2"], 1)        # both Gold
  expect_equal(sim$S["G1", "B1"], 0)        # Gold vs Blue
})

test_that("crit_ordinal ranks by levels", {
  log <- data.frame(
    case = c("a", "b", "c"), act = "x",
    ts = as.POSIXct("2020-01-01", tz = "UTC"),
    triage = c("green", "yellow", "red"),
    stringsAsFactors = FALSE
  )
  tr <- as_traces(log, "case", "act", "ts")
  m <- ordinal_matrix(tr, "triage", levels = c("green", "yellow", "red"))
  expect_equal(m["a", "b"], 1)              # green(1) vs yellow(2)
  expect_equal(m["a", "c"], 2)              # green(1) vs red(3)
  expect_error(
    ordinal_matrix(tr, "triage", levels = c("green", "yellow")),
    "outside `levels`"
  )
})

test_that("crit_numeric differences after a transform", {
  log <- data.frame(
    case = c("a", "b"), act = "x",
    ts = as.POSIXct("2020-01-01", tz = "UTC"),
    amount = c(1, 100), stringsAsFactors = FALSE
  )
  tr <- as_traces(log, "case", "act", "ts")
  m_id  <- numeric_matrix(tr, "amount", identity)
  m_log <- numeric_matrix(tr, "amount", log10)
  expect_equal(m_id["a", "b"], 99)
  expect_equal(m_log["a", "b"], 2)          # log10(100) - log10(1)
})

test_that("missing attributes are reported", {
  tr <- toy_traces()
  crit <- crit_nominal("nope")
  expect_error(suppressMessages(outrank_similarity(tr, crit)), "not found")
})
