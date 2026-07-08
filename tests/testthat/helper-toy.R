# A tiny event log with hand-computable measures.
#
# Cases (order of first appearance A, B, C); activities sort to X, Y, Z so the
# integer codes are X = 1, Y = 2, Z = 3.
#   A: X, Y, Z   (times 0, 60, 120 s  -> duration 2 min)
#   B: X, Y, Z   (identical to A       -> duration 2 min)
#   C: X, X      (times 0, 600 s       -> duration 10 min)
toy_log <- function() {
  base <- as.POSIXct("2020-01-01 00:00:00", tz = "UTC")
  data.frame(
    case   = c("A", "A", "A", "B", "B", "B", "C", "C"),
    act    = c("X", "Y", "Z", "X", "Y", "Z", "X", "X"),
    ts     = base + c(0, 60, 120, 0, 60, 120, 0, 600),
    status = c("open", "open", "open", "shut", "shut", "shut", "open", "open"),
    stringsAsFactors = FALSE
  )
}

toy_traces <- function() {
  as_traces(toy_log(), case_id = "case", activity = "act", timestamp = "ts")
}
