# Plots are exercised for "runs without error"; correctness of the visuals is
# out of scope for unit tests.

test_that("all plot types render without error", {
  grDevices::pdf(tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off())

  spectral <- cluster_traces(attr_sim(), k = 2, seed = 1)
  hier     <- cluster_traces(attr_sim(), k = 2, method = "hierarchical")

  expect_no_error(plot(spectral, type = "eigenvalues"))
  expect_no_error(plot(spectral, type = "dendrogram"))   # built on the fly
  expect_no_error(plot(hier, type = "dendrogram"))       # uses the tree
  expect_no_error(plot(spectral, type = "profile", attribute = "grp"))
})

test_that("profile plot requires a known attribute", {
  grDevices::pdf(tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off())
  clust <- cluster_traces(attr_sim(), k = 2, seed = 1)
  expect_error(plot(clust, type = "profile"), "attribute")
  expect_error(plot(clust, type = "profile", attribute = "nope"), "attribute")
})
