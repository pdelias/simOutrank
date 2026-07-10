# Process-aware criterion helpers. Each wraps criterion() around one of the
# internal measures with defaults appropriate to its direction. All defaults
# are quantile specifications resolved on the criterion's own value
# distribution, and every one is overridable.

#' Process-aware criteria
#'
#' Convenience constructors that build a [criterion()] from a trace measure,
#' with sensible, overridable quantile-threshold defaults. The similarity
#' measures (`crit_activity_profile()`, `crit_transitions()`) point in the
#' `"similarity"` direction; the distance measures point in the
#' `"dissimilarity"` direction.
#'
#' @details
#' * `crit_activity_profile()` -- cosine similarity of activity count vectors.
#' * `crit_transitions()` -- cosine similarity of distance-weighted transition
#'   profiles (weight `1 / gap`), as in the foundations paper.
#' * `crit_edit_distance()` -- OSA edit distance on the integer-encoded traces.
#' * `crit_trace_length()` -- `|n_a - n_b|`, the difference in event counts.
#' * `crit_distinct_activities()` -- difference in the number of distinct
#'   activities.
#' * `crit_duration()` -- difference in case duration.
#'
#' @param weight A single positive weight (normalised later, when the
#'   similarity matrix is built).
#' @param indifference,similarity,veto Thresholds, each a number or an
#'   [as_quantile()] quantile specification. The defaults differ by direction
#'   and are documented in the argument defaults.
#' @param method Edit-distance method passed to
#'   [stringdist::seq_distmatrix()].
#' @param units Time unit for durations, passed to [base::difftime()].
#' @param name Criterion label.
#' @return A [criterion()] object.
#' @seealso [crit_nominal()], [crit_ordinal()], [crit_numeric()],
#'   [crit_custom()] for attribute-based criteria.
#' @name crit_process
#' @examples
#' crit_activity_profile(weight = 0.2)
#' crit_edit_distance(weight = 0.2, similarity = 2, indifference = 3, veto = 6)
NULL

#' @rdname crit_process
#' @export
crit_activity_profile <- function(weight = 1,
                                  indifference = as_quantile(0.5),
                                  similarity = as_quantile(0.8),
                                  veto = NULL,
                                  name = "activity_profile") {
  criterion(function(traces) measure_activity_profile(traces),
            "similarity", weight, indifference, similarity, veto, name)
}

#' @rdname crit_process
#' @export
crit_transitions <- function(weight = 1,
                             indifference = as_quantile(0.5),
                             similarity = as_quantile(0.8),
                             veto = NULL,
                             name = "transitions") {
  criterion(function(traces) measure_transitions(traces),
            "similarity", weight, indifference, similarity, veto, name)
}

#' @rdname crit_process
#' @export
crit_edit_distance <- function(weight = 1, method = "osa",
                               indifference = as_quantile(0.5),
                               similarity = as_quantile(0.2),
                               veto = NULL,
                               name = "edit_distance") {
  criterion(function(traces) measure_edit_distance(traces, method = method),
            "dissimilarity", weight, indifference, similarity, veto, name)
}

#' @rdname crit_process
#' @export
crit_trace_length <- function(weight = 1,
                              indifference = as_quantile(0.5),
                              similarity = as_quantile(0.2),
                              veto = NULL,
                              name = "trace_length") {
  criterion(function(traces) measure_trace_length(traces),
            "dissimilarity", weight, indifference, similarity, veto, name)
}

#' @rdname crit_process
#' @export
crit_distinct_activities <- function(weight = 1,
                                     indifference = as_quantile(0.5),
                                     similarity = as_quantile(0.2),
                                     veto = NULL,
                                     name = "distinct_activities") {
  criterion(function(traces) measure_distinct_activities(traces),
            "dissimilarity", weight, indifference, similarity, veto, name)
}

#' @rdname crit_process
#' @export
crit_duration <- function(weight = 1, units = "mins",
                          indifference = as_quantile(0.5),
                          similarity = as_quantile(0.2),
                          veto = NULL,
                          name = "duration") {
  criterion(function(traces) measure_duration(traces, units = units),
            "dissimilarity", weight, indifference, similarity, veto, name)
}
