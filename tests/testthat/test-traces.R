test_that("as_traces builds the expected structure", {
  tr <- toy_traces()

  expect_s3_class(tr, "traces")
  expect_equal(tr$case_ids, c("A", "B", "C"))
  # Activities are sorted and integer-encoded.
  expect_equal(tr$activities, c("X", "Y", "Z"))
  expect_equal(tr$sequences$A, c(1L, 2L, 3L))
  expect_equal(tr$sequences$C, c(1L, 1L))
  expect_type(tr$sequences$A, "integer")
})

test_that("case attributes take the first value per case", {
  tr <- toy_traces()

  expect_equal(rownames(tr$case_attributes), c("A", "B", "C"))
  expect_equal(tr$case_attributes$status, c("open", "shut", "open"))
})

test_that("events are ordered by timestamp within case", {
  base <- as.POSIXct("2020-01-01 00:00:00", tz = "UTC")
  # Rows deliberately out of time order.
  log <- data.frame(
    case = c("A", "A", "A"),
    act  = c("Z", "X", "Y"),
    ts   = base + c(120, 0, 60),
    stringsAsFactors = FALSE
  )
  tr <- as_traces(log, "case", "act", "ts")
  # Sorted activities X, Y, Z -> codes 1, 2, 3 in time order.
  expect_equal(tr$sequences$A, c(1L, 2L, 3L))
})

test_that("tied timestamps warn and fall back to row order", {
  base <- as.POSIXct("2020-01-01 00:00:00", tz = "UTC")
  log <- data.frame(
    case = c("A", "A"),
    act  = c("X", "Y"),
    ts   = base + c(0, 0),
    stringsAsFactors = FALSE
  )
  expect_warning(tr <- as_traces(log, "case", "act", "ts"), "[Tt]ied")
  expect_equal(tr$sequences$A, c(1L, 2L))
})

test_that("missing columns and bad inputs are rejected", {
  log <- toy_log()
  expect_error(as_traces(log, "nope", "act", "ts"), "not found")
  expect_error(as_traces(log[0, ], "case", "act", "ts"), "no rows")
  # A non-time, non-numeric timestamp column is rejected.
  bad <- log
  bad$ts <- as.character(bad$ts)
  expect_error(as_traces(bad, "case", "act", "ts"), "POSIXct")
})

test_that("print and summary work", {
  tr <- toy_traces()
  expect_output(print(tr), "<traces>")
  s <- summary(tr)
  expect_equal(s$case_id, c("A", "B", "C"))
  expect_equal(s$n_events, c(3L, 3L, 2L))
  expect_equal(s$n_distinct, c(3L, 3L, 1L))
})
