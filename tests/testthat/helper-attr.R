# A 4-case sim carrying a "grp" case attribute (a,b -> "G"; c,d -> "B"), with a
# flat 0.5 off-diagonal similarity so constraint algebra is easy to read.
attr_sim <- function() {
  log <- data.frame(
    case = rep(c("a", "b", "c", "d"), each = 2),
    act  = rep(c("x", "y"), 4),
    ts   = as.POSIXct("2020-01-01", tz = "UTC") + (0:7) * 60,
    grp  = rep(c("G", "G", "B", "B"), each = 2),
    stringsAsFactors = FALSE
  )
  tr <- as_traces(log, "case", "act", "ts")
  m <- matrix(0.5, 4, 4)
  diag(m) <- 1
  dimnames(m) <- list(letters[1:4], letters[1:4])
  crit <- criterion(m, "similarity", indifference = 0.1, similarity = 0.9)
  suppressMessages(outrank_similarity(tr, crit))
}

# A 5-case sim in which case "5" is a clear outlier (low similarity to all).
outlier_sim <- function() {
  m <- matrix(0.8, 5, 5)
  m[5, ] <- 0.05
  m[, 5] <- 0.05
  diag(m) <- 1
  dimnames(m) <- list(1:5, 1:5)
  structure(
    list(S = m, C = m, D = 1 - m, case_ids = as.character(1:5),
         criteria = list(), case_attributes = NULL, partials = NULL),
    class = "outrank_sim"
  )
}
