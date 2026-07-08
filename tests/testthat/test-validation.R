test_that("validate_clusters returns connectivity and Dunn", {
  skip_if_not_installed("clValid")
  clust <- cluster_traces(illustrative_sim(), k = 4, seed = 42)
  v <- validate_clusters(clust)

  expect_named(v, c("connectivity", "dunn"))
  expect_length(v, 2L)
  expect_true(all(is.finite(v)))
})

test_that("validate_clusters rejects non-clusterings", {
  expect_error(validate_clusters(list()), "outrank_clust")
})

test_that("augment_log joins memberships onto the event log", {
  log <- data.frame(
    case = rep(c("a", "b", "c", "d"), each = 2),
    act  = rep(c("x", "y"), 4),
    ts   = as.POSIXct("2020-01-01", tz = "UTC") + (0:7) * 60,
    grp  = rep(c("G", "G", "B", "B"), each = 2),
    stringsAsFactors = FALSE
  )
  clust <- cluster_traces(attr_sim(), k = 2, seed = 1)
  expect_message(aug <- augment_log(clust, log), "case-id column 'case'")

  expect_true(".cluster" %in% names(aug))
  expect_equal(nrow(aug), nrow(log))
  # Every event of a case gets that case's cluster.
  expect_equal(unique(aug$.cluster[aug$case == "a"]),
               unname(clust$memberships[["a"]]))
})

test_that("augment_log errors when no column carries the case ids", {
  clust <- cluster_traces(attr_sim(), k = 2, seed = 1)
  bad <- data.frame(activity = c("x", "y"), value = 1:2)
  expect_error(augment_log(clust, bad), "case ids")
})
