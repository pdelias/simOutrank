# Internal measure functions.
#
# Each takes a `traces` object and returns a symmetric numeric matrix of the
# pairwise values of one criterion, with dimnames equal to the case ids. All
# are written with vectorised matrix operations (no `apply(X, 1:2, f)` over
# the pair matrix); any loops run once per trace, never once per pair.

## Cosine similarity of the rows of a profile matrix.
##
## Rows with zero norm (e.g. a trace with no transitions) contribute a zero
## similarity to every case rather than NaN.
cosine_matrix <- function(x, ids) {
  nrm <- sqrt(rowSums(x * x))
  nz  <- nrm > 0
  xn  <- x
  xn[nz, ] <- x[nz, , drop = FALSE] / nrm[nz]
  s <- tcrossprod(xn)
  dimnames(s) <- list(ids, ids)
  s
}

#' Activity-profile similarity
#'
#' Cosine similarity of the activity count vectors of each pair of traces.
#'
#' @details For a trace \eqn{a} let \eqn{n_a} be the vector whose \eqn{k}-th
#'   entry counts the occurrences of activity \eqn{k}. The measure is
#'   \deqn{g(a, b) = \frac{n_a \cdot n_b}{\lVert n_a \rVert \, \lVert n_b \rVert}.}
#'
#' @param traces A `traces` object.
#' @return A symmetric numeric matrix of similarities in `[0, 1]`.
#' @noRd
measure_activity_profile <- function(traces) {
  seqs  <- traces$sequences
  n_act <- length(traces$activities)
  counts <- t(vapply(seqs, function(s) tabulate(s, nbins = n_act),
                     numeric(n_act)))
  cosine_matrix(counts, names(seqs))
}

#' Transition-profile similarity
#'
#' Cosine similarity of distance-weighted transition profiles, following the
#' foundations paper.
#'
#' @details Within a trace, every ordered pair of positions \eqn{(p, q)} with
#'   \eqn{p < q} contributes weight \eqn{1 / (q - p)} to the transition from
#'   the activity at \eqn{p} to the activity at \eqn{q}. The per-trace profile
#'   is the vector of accumulated weights over the \eqn{K^2} possible
#'   transitions (\eqn{K} activities), and the measure is the cosine
#'   similarity of these profiles.
#'
#'   The pair indices are built by combn-free index arithmetic and the weights
#'   accumulated with `rowsum`, once per trace.
#'
#' @param traces A `traces` object.
#' @return A symmetric numeric matrix of similarities in `[0, 1]`.
#' @noRd
measure_transitions <- function(traces) {
  seqs  <- traces$sequences
  n_act <- length(traces$activities)
  n     <- length(seqs)
  prof  <- matrix(0, nrow = n, ncol = n_act * n_act)
  for (k in seq_len(n)) {
    s <- seqs[[k]]
    len <- length(s)
    if (len > 1L) {
      reps    <- (len - 1L):1L
      starts  <- rep.int(seq_len(len - 1L), reps)
      offsets <- sequence(reps)
      ends    <- starts + offsets
      tcode   <- (s[starts] - 1L) * n_act + s[ends]
      agg     <- rowsum(1 / offsets, tcode)
      prof[k, as.integer(rownames(agg))] <- agg[, 1L]
    }
  }
  cosine_matrix(prof, names(seqs))
}

#' Edit-distance dissimilarity
#'
#' Optimal String Alignment (OSA) distance between the integer-encoded
#' activity sequences, computed with [stringdist::seq_distmatrix()].
#'
#' @param traces A `traces` object.
#' @param method Passed to [stringdist::seq_distmatrix()]; defaults to `"osa"`.
#' @return A symmetric numeric matrix of distances with a zero diagonal.
#' @noRd
measure_edit_distance <- function(traces, method = "osa") {
  seqs <- traces$sequences
  m <- as.matrix(stringdist::seq_distmatrix(seqs, method = method))
  dimnames(m) <- list(names(seqs), names(seqs))
  m
}

## Absolute pairwise differences of a per-case numeric vector, as a symmetric
## matrix with case-id dimnames.
abs_diff_matrix <- function(values, ids) {
  m <- abs(outer(values, values, "-"))
  dimnames(m) <- list(ids, ids)
  m
}

#' Trace-length dissimilarity
#'
#' Absolute difference in the number of events per trace, \eqn{|n_a - n_b|}.
#'
#' @param traces A `traces` object.
#' @return A symmetric numeric matrix of distances with a zero diagonal.
#' @noRd
measure_trace_length <- function(traces) {
  lens <- lengths(traces$sequences)
  abs_diff_matrix(as.numeric(lens), names(traces$sequences))
}

#' Distinct-activities dissimilarity
#'
#' Absolute difference in the number of distinct activities per trace.
#'
#' @param traces A `traces` object.
#' @return A symmetric numeric matrix of distances with a zero diagonal.
#' @noRd
measure_distinct_activities <- function(traces) {
  u <- vapply(traces$sequences, function(s) length(unique(s)), integer(1L))
  abs_diff_matrix(as.numeric(u), names(traces$sequences))
}

#' Duration dissimilarity
#'
#' Absolute difference in case duration, \eqn{|d_a - d_b|}, where the duration
#' is the span between the first and last event of a case.
#'
#' @param traces A `traces` object.
#' @param units Time unit for the duration; passed to [base::difftime()] when
#'   the timestamps are date/times. Defaults to `"mins"`.
#' @return A symmetric numeric matrix of distances with a zero diagonal.
#' @noRd
measure_duration <- function(traces, units = "mins") {
  dur <- vapply(traces$times, function(t) {
    if (length(t) < 1L) return(NA_real_)
    if (inherits(t, c("POSIXct", "POSIXt", "Date"))) {
      as.numeric(difftime(max(t), min(t), units = units))
    } else {
      as.numeric(max(t) - min(t))
    }
  }, numeric(1L))
  abs_diff_matrix(dur, names(traces$times))
}
