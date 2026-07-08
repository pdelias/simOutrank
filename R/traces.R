#' Represent an event log as traces
#'
#' `as_traces()` converts an event log into a `traces` object: the
#' time-ordered activity sequence of every case together with the case-level
#' attribute table. Activities are encoded as integers internally (never as
#' single letters) so that logs with more than 26 activities or with
#' multi-character labels are handled correctly; the original labels are kept
#' for display and decoding.
#'
#' @param x An event log. A `data.frame` in which each row is an event, or --
#'   when the \pkg{bupaR} package is installed -- a bupaR `eventlog` or
#'   `activitylog`.
#' @param case_id,activity,timestamp Length-one character strings naming the
#'   columns that hold the case identifier, the activity label and the event
#'   timestamp. For the bupaR methods the mapping is read from the object and
#'   these arguments must not be supplied.
#' @param ... Passed on to methods.
#'
#' @details
#' Events are ordered by `timestamp` within each case. Ties (two events of the
#' same case sharing a timestamp) are broken by the original row order and
#' raise a warning. Cases keep their order of first appearance in `x`.
#'
#' Every column other than `case_id`, `activity` and `timestamp` is treated as
#' a case-level attribute and summarised by its first value within the ordered
#' case, matching the convention that such attributes are constant per case.
#'
#' @return An object of class `traces`, a list with elements:
#'   \describe{
#'     \item{`case_ids`}{character vector of case identifiers, in order.}
#'     \item{`sequences`}{named list of integer vectors; each entry is the
#'       time-ordered activity sequence of a case, encoded against
#'       `activities`.}
#'     \item{`activities`}{character vector of distinct activity labels; the
#'       integer code `i` in `sequences` refers to `activities[i]`.}
#'     \item{`times`}{named list of the ordered event timestamps per case.}
#'     \item{`case_attributes`}{data frame of case-level attributes, one row
#'       per case, row names equal to the case identifiers.}
#'   }
#'
#' @examples
#' log <- data.frame(
#'   case = c("c1", "c1", "c2", "c2"),
#'   act  = c("register", "decide", "register", "reject"),
#'   ts   = as.POSIXct("2020-01-01") + c(0, 60, 0, 90),
#'   status = c("open", "open", "closed", "closed")
#' )
#' as_traces(log, case_id = "case", activity = "act", timestamp = "ts")
#'
#' @export
as_traces <- function(x, ...) {
  UseMethod("as_traces")
}

#' @rdname as_traces
#' @export
as_traces.data.frame <- function(x, case_id, activity, timestamp, ...) {
  for (nm in c("case_id", "activity", "timestamp")) {
    val <- get(nm)
    if (!is.character(val) || length(val) != 1L) {
      stop(sprintf("`%s` must be a single column name.", nm), call. = FALSE)
    }
  }
  cols <- c(case_id, activity, timestamp)
  missing_cols <- setdiff(cols, names(x))
  if (length(missing_cols)) {
    stop("Column(s) not found in `x`: ",
         paste(missing_cols, collapse = ", "), ".", call. = FALSE)
  }
  if (nrow(x) == 0L) {
    stop("`x` has no rows.", call. = FALSE)
  }

  cid <- as.character(x[[case_id]])
  act <- as.character(x[[activity]])
  ts  <- x[[timestamp]]
  if (!(inherits(ts, c("POSIXct", "POSIXt", "Date")) || is.numeric(ts))) {
    stop("`timestamp` column must be POSIXct, Date or numeric; got ",
         class(ts)[1L], ".", call. = FALSE)
  }
  if (anyNA(cid) || anyNA(act)) {
    stop("`case_id` and `activity` columns must not contain missing values.",
         call. = FALSE)
  }

  case_levels <- unique(cid)
  activities  <- sort(unique(act))
  code        <- match(act, activities)

  ## Order events by (case appearance, timestamp), with the original row
  ## order as the final tie-break so the sort is stable.
  row_idx <- seq_len(nrow(x))
  ord <- order(match(cid, case_levels), ts, row_idx)

  if (anyDuplicated(data.frame(cid, ts, stringsAsFactors = FALSE))) {
    warning("Tied timestamps within a case were ordered by original row order.",
            call. = FALSE)
  }

  cid  <- cid[ord]
  code <- code[ord]
  ts   <- ts[ord]
  cid_f <- factor(cid, levels = case_levels)

  sequences <- split(code, cid_f)
  times     <- split(ts, cid_f)

  attr_cols <- setdiff(names(x), cols)
  first     <- !duplicated(cid)
  case_attr <- x[ord, attr_cols, drop = FALSE][first, , drop = FALSE]
  rownames(case_attr) <- cid[first]
  case_attr <- case_attr[case_levels, , drop = FALSE]

  new_traces(case_levels, sequences, activities, times, case_attr)
}

## Internal constructor: assumes its arguments are already validated and
## consistently ordered on `case_ids`.
new_traces <- function(case_ids, sequences, activities, times, case_attributes) {
  structure(
    list(
      case_ids        = case_ids,
      sequences       = sequences,
      activities      = activities,
      times           = times,
      case_attributes = case_attributes
    ),
    class = "traces"
  )
}

#' @rdname as_traces
#' @export
as_traces.eventlog <- function(x, ...) {
  as_traces(as.data.frame(x),
            case_id   = bupaR::case_id(x),
            activity  = bupaR::activity_id(x),
            timestamp = bupaR::timestamp(x),
            ...)
}

#' @rdname as_traces
#' @export
as_traces.activitylog <- function(x, ...) {
  as_traces(bupaR::to_eventlog(x), ...)
}

#' @export
print.traces <- function(x, ...) {
  lens <- lengths(x$sequences)
  na   <- ncol(x$case_attributes)
  cat(sprintf("<traces>: %d cases, %d distinct activities\n",
              length(x$case_ids), length(x$activities)))
  cat(sprintf("  trace length: min %d, median %g, max %d\n",
              min(lens), stats::median(lens), max(lens)))
  cat(sprintf("  case attributes: %s\n",
              if (na) paste(names(x$case_attributes), collapse = ", ") else "none"))
  invisible(x)
}

#' Per-case summary of a `traces` object
#'
#' @param object A `traces` object.
#' @param ... Unused.
#' @return A data frame with one row per case giving the number of events and
#'   the number of distinct activities.
#' @export
summary.traces <- function(object, ...) {
  seqs <- object$sequences
  data.frame(
    case_id    = object$case_ids,
    n_events   = as.integer(lengths(seqs)),
    n_distinct = vapply(seqs, function(s) length(unique(s)), integer(1L)),
    row.names  = NULL,
    stringsAsFactors = FALSE
  )
}
