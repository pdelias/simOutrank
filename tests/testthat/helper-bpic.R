# The BPIC'11 similarity matrix is kept local-only (4TU General Terms of Use;
# not redistributed -- see dev/fixtures/README.md). These helpers load it when
# present; the tests that use them skip on CRAN and when the fixture is absent.

bpic_fixture_path <- function() {
  test_path("fixtures", "similarity_ord.rds")
}

skip_if_no_bpic <- function() {
  testthat::skip_on_cran()
  if (!file.exists(bpic_fixture_path())) {
    testthat::skip("BPIC'11 fixture not available (kept local-only).")
  }
}

# Wrap the bare similarity matrix as an outrank_sim, assigning sequential case
# ids (the saved matrix has no dimnames).
load_bpic_sim <- function() {
  s <- readRDS(bpic_fixture_path())
  ids <- as.character(seq_len(nrow(s)))
  dimnames(s) <- list(ids, ids)
  structure(
    list(S = s, C = s, D = 1 - s, case_ids = ids,
         criteria = list(), case_attributes = NULL, partials = NULL),
    class = "outrank_sim"
  )
}
