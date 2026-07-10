# Builds `illustrative_log` from the authoritative CSV of Delias et al. (2023),
# "Improving the non-compensatory trace-clustering decision process",
# Intl. Trans. in Op. Res., 30(3), 1387-1406. doi:10.1111/itor.13062 (Table 1).
#
# Source file: dev/fixtures/Illustrative_event_Log.csv (UTF-8 BOM, CRLF, clock
# timestamps). Run with: source("data-raw/illustrative_log.R")

raw_path <- "dev/fixtures/Illustrative_event_Log.csv"

lines <- readLines(raw_path, warn = FALSE)
lines <- sub("^﻿", "", lines)          # strip UTF-8 BOM
lines <- gsub("\r", "", lines)               # normalise CRLF

df <- utils::read.csv(text = lines, stringsAsFactors = FALSE,
                      colClasses = "character")
names(df) <- tolower(names(df))
names(df)[names(df) == "case.id"] <- "case_id"

# Clock timestamps ("H:M:S" elapsed) -> POSIXct on a nominal base date.
secs <- as.numeric(as.difftime(df$timestamp, format = "%H:%M:%S",
                               units = "secs"))
stopifnot(!anyNA(secs))

illustrative_log <- data.frame(
  case_id      = df$case_id,
  activity     = df$activity,
  timestamp    = as.POSIXct("2021-01-01", tz = "UTC") + secs,
  status       = df$status,
  satisfaction = df$satisfaction,
  stringsAsFactors = FALSE
)

stopifnot(
  length(unique(illustrative_log$case_id)) == 25L,
  nrow(illustrative_log) == 117L,
  setequal(illustrative_log$status, c("GOLD", "NORMAL")),
  setequal(illustrative_log$satisfaction, c("High", "Low"))
)

usethis::use_data(illustrative_log, overwrite = TRUE)
