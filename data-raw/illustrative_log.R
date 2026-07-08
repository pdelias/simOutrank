# Builds `illustrative_log` from Table 1 of Delias et al. (2021), "Improving
# the non-compensatory trace clustering", Intl. Trans. in Op. Res.
#
# Run with: source("data-raw/illustrative_log.R")

# Trace | Status | Satisfaction | case ids (Table 1).
profiles <- list(
  list(trace = c("B", "E"),                     status = "Gold", satisfaction = "HIGH",
       cases = c("G1", "G2", "G3", "G4", "G5")),
  list(trace = c("B", "E", "C", "D", "E"),      status = "Gold", satisfaction = "HIGH",
       cases = c("G6", "G7", "G8")),
  list(trace = c("B", "E", "C", "D", "E"),      status = "Gold", satisfaction = "LOW",
       cases = c("G9", "G10")),
  list(trace = c("A", "C", "D", "E"),           status = "Blue", satisfaction = "HIGH",
       cases = c("B1", "B2", "B3", "B4", "B5")),
  list(trace = c("A", "C", "D", "E", "C", "D", "E"), status = "Blue", satisfaction = "HIGH",
       cases = c("B6", "B7", "B8", "B9", "B10", "B11")),
  list(trace = c("A", "C", "D", "E", "C", "D", "E"), status = "Blue", satisfaction = "LOW",
       cases = c("B12", "B13")),
  list(trace = c("A", "B", "E"),                status = "Blue", satisfaction = "HIGH",
       cases = "B14"),
  list(trace = c("C", "B", "E"),                status = "Gold", satisfaction = "HIGH",
       cases = "G11")
)

base_time <- as.POSIXct("2021-01-01 00:00:00", tz = "UTC")

rows <- list()
for (p in profiles) {
  for (case in p$cases) {
    n <- length(p$trace)
    rows[[length(rows) + 1L]] <- data.frame(
      case_id      = case,
      activity     = p$trace,
      timestamp    = base_time + (seq_len(n) - 1L) * 60,
      status       = p$status,
      satisfaction = p$satisfaction,
      stringsAsFactors = FALSE
    )
  }
}

# Order cases as in Table 1 (G-group first appearance, then B-groups, ...).
illustrative_log <- do.call(rbind, rows)
rownames(illustrative_log) <- NULL

stopifnot(
  length(unique(illustrative_log$case_id)) == 25L,
  nrow(illustrative_log) == sum(vapply(profiles,
    function(p) length(p$trace) * length(p$cases), integer(1)))
)

usethis::use_data(illustrative_log, overwrite = TRUE)
